import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/typedefs.dart';
import '../entities/app_user.dart';
import '../entities/emergency_alert.dart';
import '../entities/friendship.dart';

extension DocumentSnapshotX on DocumentSnapshot<Json> {
  Friendship toFriendship() {
    return Friendship(
      id: id,
      users: (this['users'] as List).map((e) => e.toString()).toList(),
      sender: this['sender'],
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == this['status'],
        orElse: () => FriendshipStatus.archived,
      ),
      createdAt: DateTime.parse(this['createdAt']),
      updatedAt: DateTime.parse(this['updatedAt']),
    );
  }

  EmergencyAlert toEmergencyAlert() {
    return EmergencyAlert(
      id: id,
      sender: this['sender'],
      recipient: this['recipient'],
      createdAt: (this['createdAt'] as Timestamp).toDate(),
    );
  }

  AppUser toAppUser() {
    return AppUser(
      id: this['id'],
      username: this['username'],
      email: this['email'],
      photoUrl: this['photoUrl'],
    );
  }
}
