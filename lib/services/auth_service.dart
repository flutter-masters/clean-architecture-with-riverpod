import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../core/typedefs.dart';
import '../entities/app_user.dart';
import '../failures/auth_failure.dart';

extension type AuthService(FirebaseAuth auth) {
  FutureAuthResult<void, SignInAuthFailure> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credentials.user == null) {
        return Error(SignInAuthFailure.userNotFound);
      }
      return Success(null);
    } on FirebaseAuthException catch (e) {
      return Error(
        SignInAuthFailure.values.firstWhere(
          (failure) => failure.code == e.code,
          orElse: () => SignInAuthFailure.unknown,
        ),
      );
    } catch (_) {
      return Error(SignInAuthFailure.unknown);
    }
  }

  FutureAuthResult<AppUser, SignUpAuthFailure> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credentials.user;
      if (user == null) {
        return Error(SignUpAuthFailure.userNotCreate);
      }
      return Success(
        AppUser(
          id: user.uid,
          username: user.displayName,
          email: email,
          photoUrl: user.photoURL,
        ),
      );
    } on FirebaseAuthException catch (e) {
      return Error(SignUpAuthFailure.values.firstWhere(
        (failure) => failure.code == e.code,
        orElse: () => SignUpAuthFailure.unknown,
      ));
    } catch (_) {
      return Error(SignUpAuthFailure.unknown);
    }
  }

  bool get isSignedIn => _currentUser != null;

  AppUser? get currentUser {
    if (_currentUser == null) {
      return null;
    }
    return AppUser(
      id: _currentUser!.uid,
      username: _currentUser!.displayName,
      email: _currentUser!.email,
      photoUrl: _currentUser!.photoURL,
    );
  }

  User? get _currentUser => auth.currentUser;

  Future<void> logout() => auth.signOut();
}
