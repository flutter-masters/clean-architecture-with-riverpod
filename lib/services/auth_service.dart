import 'package:firebase_auth/firebase_auth.dart';

import '../failures/auth_failure.dart';

extension type AuthService(FirebaseAuth auth) {
  Future<SignInAuthFailure?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credentials.user == null) {
        return SignInAuthFailure.userNotFound;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return SignInAuthFailure.values.firstWhere(
        (failure) => failure.code == e.code,
        orElse: () => SignInAuthFailure.unknown,
      );
    } catch (_) {
      return SignInAuthFailure.unknown;
    }
  }

  Future<SignUpAuthFailure?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return SignUpAuthFailure.values.firstWhere(
        (failure) => failure.code == e.code,
        orElse: () => SignUpAuthFailure.unknown,
      );
    } catch (_) {
      return SignUpAuthFailure.unknown;
    }
  }

  bool get isSignedIn => auth.currentUser != null;
}
