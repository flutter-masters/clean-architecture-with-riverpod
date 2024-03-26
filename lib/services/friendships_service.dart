import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/typedefs.dart';
import '../entities/app_user.dart';
import '../entities/emergency_alert.dart';
import '../entities/friendship.dart';
import '../extensions/document_snapshot_x.dart';

extension type FriendshipsService(FirebaseFirestore _db) {
  CollectionReference<Json> get _collection => _db.collection('friendships');

  Future<Map<String, String>> _friendsIds(String userId) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: FriendshipStatus.active.name)
          .where('users', arrayContains: userId)
          .get();
      final pendingsRequests =
          snapshot.docs.map((e) => e.toFriendship()).toList();
      final friendships = <String, String>{};
      for (var pendingsRequest in pendingsRequests) {
        final id = pendingsRequest.users.firstWhere((id) => id != userId);
        friendships.addAll({id: pendingsRequest.id});
      }
      return friendships;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, String>> _pendingFriendshipRequestIds(
    String userId,
  ) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: FriendshipStatus.pending.name)
          .where('users', arrayContains: userId)
          .where('sender', isNotEqualTo: userId)
          .get();
      final pendingsRequests =
          snapshot.docs.map((e) => e.toFriendship()).toList();
      final friendships = <String, String>{};
      for (var pendingsRequest in pendingsRequests) {
        final id = pendingsRequest.users.firstWhere((id) => id != userId);
        friendships.addAll({id: pendingsRequest.id});
      }
      return friendships;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, String>> _pendingFriendshipRequestSendIds(
    String userId,
  ) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: FriendshipStatus.pending.name)
          .where('users', arrayContains: userId)
          .where('sender', isEqualTo: userId)
          .get();
      final pendingsRequests =
          snapshot.docs.map((e) => e.toFriendship()).toList();
      final friendships = <String, String>{};
      for (var pendingsRequest in pendingsRequests) {
        final id = pendingsRequest.users.firstWhere((id) => id != userId);
        friendships.addAll({id: pendingsRequest.id});
      }
      return friendships;
    } catch (_) {
      return {};
    }
  }

  Future<List<AppUser>?> _filterUsers(
    String userId,
    List<String>? filterIds,
  ) async {
    try {
      final query = _db.collection('users').where('id', whereIn: filterIds);
      final snapshot = await query.get();
      final docs = snapshot.docs.where((doc) => doc.id != userId).toList();
      return docs.map((e) => e.toAppUser()).toList();
    } catch (_) {
      return null;
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
      (event) => event.docs.map(
        (doc) {
          return doc.toEmergencyAlert();
        },
      ).toList(),
    );
  }

  Future<
      ({
        List<AppUser>? friends,
        Map<String, String>? friendships,
      })> getFriends(String userId) async {
    try {
      final friendships = await _friendsIds(userId);
      final friendsIds = friendships.entries.map((e) => e.key).toList();
      final query = _db.collection('users').where('id', whereIn: friendsIds);
      final snapshot = await query.get();
      return (
        friends: snapshot.docs
            .where((e) => e.exists)
            .map((doc) => doc.toAppUser())
            .toList(),
        friendships: friendships,
      );
    } catch (_) {
      return (friends: null, friendships: null);
    }
  }

  Future<
      ({
        List<AppUser>? users,
        Map<String, String>? friendsIds,
        Map<String, String>? pendingsRequestsSentIds,
      })> searchUsers(String userId) async {
    try {
      final friendIds = await _friendsIds(userId);
      final pendingsFriendshipsSentIds = await _pendingFriendshipRequestSendIds(
        userId,
      );
      final users = await _filterUsers(userId, null);
      return (
        users: users,
        friendsIds: friendIds,
        pendingsRequestsSentIds: pendingsFriendshipsSentIds,
      );
    } catch (_) {
      return (
        users: null,
        friendsIds: null,
        pendingsRequestsSentIds: null,
      );
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

  Future<
      ({
        List<AppUser>? users,
        Map<String, String>? friendships,
      })> getFriendshipRequests(String userId) async {
    try {
      final pendingsRequests = await _pendingFriendshipRequestIds(userId);
      if (pendingsRequests.isEmpty) {
        return (users: null, friendships: null);
      }
      final friendshipsRequests = await _filterUsers(
        userId,
        pendingsRequests.entries.map((e) => e.key).toList(),
      );
      return (users: friendshipsRequests, friendships: pendingsRequests);
    } catch (_) {
      return (users: null, friendships: null);
    }
  }

  Future<Friendship?> sendFriendshipRequest({
    required AppUser sender,
    required String recipientId,
  }) async {
    try {
      final snapshot = await _collection
          .where('users', arrayContains: recipientId)
          .where('sender', isEqualTo: sender.id)
          .get();

      final docs = snapshot.docs;
      final data = <String, dynamic>{
        'users': [sender.id, recipientId],
        'sender': sender.id,
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
        sender: sender.id,
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

  Future<bool> rejectFriendshipRequest(String friendshipId) async {
    try {
      final ref = _collection.doc(friendshipId);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        return false;
      }
      await ref.delete();
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
      final friends = await _friendsIds(userId);
      final friendsIds = friends.entries.map((e) => e.key).toList();
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
      return true;
    } catch (_) {
      return false;
    }
  }
}
