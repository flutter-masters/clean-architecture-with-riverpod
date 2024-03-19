import 'package:firebase_auth/firebase_auth.dart';

import '../failures/auth_failure.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final _firebaseAuth = FirebaseAuth.instance;

  Future<AuthFailure?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credentials.user == null) {
        return UserNotFoundFailure();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'network-request-failed' => NetworkFailure(),
        'user-not-found' => UserNotFoundFailure(),
        'invalid-email' => InvalidEmailFailure(),
        'invalid-credential' || 'wrong-password' => InvalidCredentialsFailure(),
        'user-disabled' => UserDisableFailure(),
        _ => UnknownFailure(),
      };
    } catch (_) {
      return UnknownFailure();
    }
  }

  Future<AuthFailure?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credentials.user == null) {
        return CreateUserFailure();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'network-request-failed' => NetworkFailure(),
        'email-already-in-use' => EmailExistFailure(),
        'invalid-email' => InvalidEmailFailure(),
        'weak-password' => WeakPasswordFailure(),
        _ => UnknownFailure(),
      };
    } catch (_) {
      return UnknownFailure();
    }
  }

  Future<void> logout() => _firebaseAuth.signOut();

  bool get sessionActive => currentUser != null;

  User? get currentUser => _firebaseAuth.currentUser;
}
