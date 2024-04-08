import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/result.dart';
import '../core/typedefs.dart';
import '../entities/emergency_alert.dart';
import '../entities/friendship.dart';
import '../extensions/document_snapshot_x.dart';
import '../failures/failure.dart';

extension type FriendshipsService(FirebaseFirestore _db) {
  CollectionReference<Json> get _collection => _db.collection('friendships');

  Future<List<Friendship>> _friendships(String userId) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: FriendshipStatus.active.name)
          .where('users', arrayContains: userId)
          .get();
      return snapshot.docs.map((e) => e.toFriendship()).toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<EmergencyAlert> onEmergencyAlert(String recipient) {
    final query = _db
        .collection('alerts')
        .where('recipient', isEqualTo: recipient)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
    return query.expand<EmergencyAlert>(
      (event) => event.docs.map((doc) => doc.toEmergencyAlert()).toList(),
    );
  }

  FutureResult<List<FriendshipsData>> getFriends(String userId) async {
    try {
      final friendships = await _friendships(userId);
      final friendsIds = friendships
          .map((e) => e.users.firstWhere((id) => id != userId))
          .toList();
      if (friendsIds.isEmpty) {
        return Success([]);
      }
      final query = _db.collection('users').where('id', whereIn: friendsIds);
      final snapshot = await query.get();
      final users = snapshot.docs
          .where((e) => e.exists)
          .map((doc) => doc.toAppUser())
          .toList();
      final result = <FriendshipsData>[];
      for (final user in users) {
        final friendship = friendships.firstWhere(
          (friendship) => friendship.users.contains(user.id),
        );
        result.add((user: user, friendship: friendship));
      }
      return Success(result);
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<FriendshipsData> searchUsers(String userId, String email) async {
    try {
      final usersSnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      final userDocs = usersSnapshot.docs;
      if (userDocs.isEmpty) {
        return Error(Failure(message: 'No result found...'));
      }
      final user = userDocs.first.toAppUser();
      final friendshipsSnapshot =
          await _collection.where('users', arrayContains: user.id).get();
      final friendships =
          friendshipsSnapshot.docs.map((e) => e.toFriendship()).toList();
      Friendship? friendship;
      if (friendships.isNotEmpty) {
        friendship = friendships.firstWhere((f) => f.users.contains(userId));
      }
      return Success((user: user, friendship: friendship));
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<List<FriendshipsData>> getFriendshipRequests(
      String userId) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: FriendshipStatus.pending.name)
          .where('users', arrayContains: userId)
          .where('sender', isNotEqualTo: userId)
          .get();
      final friendships = snapshot.docs.map((e) => e.toFriendship()).toList();
      final friendsIds = friendships
          .map((e) => e.users.firstWhere((id) => id != userId))
          .toList();
      if (friendsIds.isEmpty) {
        return Success([]);
      }
      final query = _db.collection('users').where('id', whereIn: friendsIds);
      final userSnapshot = await query.get();
      final users = userSnapshot.docs
          .where((e) => e.exists)
          .map((doc) => doc.toAppUser())
          .toList();
      final result = <FriendshipsData>[];
      for (final user in users) {
        final friendship = friendships.firstWhere(
          (friendship) => friendship.users.contains(user.id),
        );
        result.add((user: user, friendship: friendship));
      }
      return Success(result);
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<Friendship> sendFriendshipRequest({
    required String sender,
    required String recipientId,
  }) async {
    try {
      final snapshot = await _collection
          .where('users', arrayContains: recipientId)
          .where('sender', isEqualTo: sender)
          .get();

      final docs = snapshot.docs;
      final data = <String, dynamic>{
        'users': [sender, recipientId],
        'sender': sender,
        'status': FriendshipStatus.pending.name,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (docs.isEmpty) {
        final ref = await _collection.add(data);
        return Success((await ref.get()).toFriendship());
      }

      final friendship = docs.first.toFriendship();
      if ([
        FriendshipStatus.active,
        FriendshipStatus.pending,
      ].contains(friendship.status)) {
        return Error(
          Failure(message: 'Friendship already exists, is pending or accepted'),
        );
      }
      await _collection.doc(friendship.id).set(data, SetOptions(merge: true));
      return Success(
        Friendship(
          id: friendship.id,
          users: friendship.users,
          sender: sender,
          status: FriendshipStatus.pending,
          createdAt: friendship.createdAt,
          updatedAt: DateTime.timestamp(),
        ),
      );
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<void> acceptFriendshipRequest(
    String friendshipId,
  ) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return Error(Failure(message: 'Friendship no exists'));
      }
      await ref.set(
        {
          'status': FriendshipStatus.active.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return Success(null);
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<void> rejectFriendshipRequest(String friendshipId) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return Error(Failure(message: 'Friendship no exists'));
      }
      await ref.delete();
      return Success(null);
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<void> cancelFriendshipRequest(String friendshipId) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return Error(Failure(message: 'Friendship no exists'));
      }
      await ref.set(
        {
          'status': FriendshipStatus.archived.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return Success(null);
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  FutureResult<void> sendAlert(String userId) async {
    try {
      final friendships = await _friendships(userId);
      final friendsIds = friendships
          .map((e) => e.users.firstWhere((id) => id != userId))
          .toList();
      if (friendsIds.isEmpty) {
        return Error(Failure(message: 'You do not have friends'));
      }
      final batch = _db.batch();
      for (final recipient in friendsIds) {
        batch.set(
          _collection.doc(),
          {
            'senderId': userId,
            'recipient': recipient,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
      await batch.commit();
      return Success(null);
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }
}
