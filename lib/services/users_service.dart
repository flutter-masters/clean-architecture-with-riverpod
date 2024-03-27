import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/result.dart';
import '../core/typedefs.dart';
import '../entities/app_user.dart';
import '../extensions/document_snapshot_x.dart';
import '../failures/failure.dart';

extension type UsersService(FirebaseFirestore _db) {
  CollectionReference<Json> get _collection => _db.collection('users');

  FutureResult<AppUser> getUserById(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      if (!snapshot.exists) {
        return Error(Failure(message: 'User no exists'));
      }
      return Success(snapshot.toAppUser());
    } catch (e) {
      return Error(Failure(message: e.toString()));
    }
  }

  Future<AppUser?> createUser({
    required String userId,
    required String username,
    required String email,
    String? photoUrl,
  }) async {
    try {
      final user = AppUser(
        id: userId,
        username: username,
        email: email,
        photoUrl: photoUrl,
      );
      await _collection.doc(userId).set({
        'id': userId,
        'username': username,
        'email': email,
        'photoUrl': photoUrl,
      });
      return user;
    } catch (_) {
      return null;
    }
  }
}
