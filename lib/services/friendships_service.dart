import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/typedefs.dart';
import '../entities/app_user.dart';
import '../entities/emergency_alert.dart';
import '../entities/friendship.dart';

extension type FriendshipsService(FirebaseFirestore _db) {
  CollectionReference<Json> get _collection => _db.collection('friendships');

  Future<List<String>> _getFriendsIds(String userId) async {
    final snapshot = await _collection
        .where('status', isEqualTo: FriendshipStatus.active.name)
        .where('users', arrayContains: userId)
        .get();

    return snapshot.docs
        .map(
          (e) => (e['users'] as List<String>).firstWhere((id) => id != userId),
        )
        .toList();
  }

  Stream<EmergencyAlert> onEmergencyAlert(String recipient) {
    final query = _db
        .collection('alerts')
        .where('recipient', isEqualTo: recipient)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();

    return query.expand<EmergencyAlert>(
      (event) {
        final doc = event.docs.first;
        final json = doc.data();
        return [
          EmergencyAlert(
            id: doc.id,
            sender: json['sender'],
            recipient: json['recipient'],
            createdAt: (json['createdAt'] as Timestamp).toDate(),
          ),
        ];
      },
    );
  }

  Future<List<AppUser>?> getFriends(String userId) async {
    try {
      final friendsIds = await _getFriendsIds(userId);

      final friendsSnapshot =
          await _db.collection('users').where('id', whereIn: friendsIds).get();

      return friendsSnapshot.docs.where((e) => e.exists).map(
        (e) {
          final json = e.data();
          return AppUser(
            id: e.id,
            username: json['username'],
            email: json['email'],
            photoUrl: json['photoUrl'],
          );
        },
      ).toList();
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteFriendship(String friendshipId) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return false;
      }

      await ref.set(
        {
          'status': FriendshipStatus.archived.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Friendship>?> getFriendshipRequests(String userId) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: FriendshipStatus.pending.name)
          .where('users', arrayContains: userId)
          .where('sender', isNotEqualTo: userId)
          .get();
      return snapshot.docs.map((e) => e.toFriendship()).toList();
    } catch (_) {
      return null;
    }
  }

  Future<Friendship?> sendFriendshipRequest({
    required String senderId,
    required String recipientId,
  }) async {
    try {
      final snapshot =
          await _collection.where('users', arrayContains: recipientId).get();

      final docs = snapshot.docs;
      final data = {
        'users': [senderId, recipientId],
        'sender': senderId,
        'status': FriendshipStatus.pending.name,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (docs.isEmpty) {
        final ref = await _collection.add(data);
        return (await ref.get()).toFriendship();
      }

      final friendship = docs.first.toFriendship();
      if ([
        FriendshipStatus.active,
        FriendshipStatus.pending,
      ].contains(friendship.status)) {
        return null;
      }

      await _collection.doc(friendship.id).set(data, SetOptions(merge: true));
      return Friendship(
        id: friendship.id,
        users: friendship.users,
        sender: senderId,
        status: FriendshipStatus.pending,
        createdAt: friendship.createdAt,
        updatedAt: DateTime.timestamp(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> acceptFriendshipRequest(String friendshipId) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return false;
      }

      await ref.set(
        {
          'status': FriendshipStatus.active.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelFriendshipRequest(String friendshipId) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return false;
      }

      await ref.set(
        {
          'status': FriendshipStatus.archived.name,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendAlert(String userId) async {
    try {
      final friendsIds = await _getFriendsIds(userId);

      final batch = _db.batch();
      for (final recipient in friendsIds) {
        batch.set(
          _collection.doc(),
          {
            'sender': userId,
            'recipient': recipient,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }
      await batch.commit();
      return true;
    } catch (_) {
      return false;
    }
  }
}

extension DocumentSnapshotX on DocumentSnapshot<Json> {
  Friendship toFriendship() {
    return Friendship(
      id: id,
      users: this['users'],
      sender: this['sender'],
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == this['status'],
        orElse: () => FriendshipStatus.archived,
      ),
      createdAt: (this['createdAt'] as Timestamp).toDate(),
      updatedAt: (this['updatedAt'] as Timestamp).toDate(),
    );
  }
}
