import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/typedefs.dart';
import '../entities/app_user.dart';

extension type UsersService(FirebaseFirestore _db) {
  CollectionReference<Json> get _collection => _db.collection('users');

  Future<AppUser?> getUserById(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      if (!snapshot.exists) {
        return null;
      }
      final json = snapshot.data()!;
      return AppUser(
        id: id,
        username: json['username'],
        email: json['email'],
        photoUrl: json['photoUrl'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> createUser({
    required String userId,
    required String username,
    required String email,
    required String photoUrl,
  }) async {
    try {
      final user = AppUser(
        id: userId,
        username: username,
        email: email,
        photoUrl: photoUrl,
      );
      await _collection.doc(userId).set(
        {
          'username': user.username,
          'email': user.email,
          'photoUrl': user.photoUrl,
        },
      );
      return user;
    } catch (_) {
      return null;
    }
  }
}
