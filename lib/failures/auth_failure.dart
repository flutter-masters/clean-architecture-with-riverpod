enum SignInAuthFailure {
  network('network-request-failed'),
  userNotFound('user-not-found'),
  invalidEmail('invalid-email'),
  wrongPassword('wrong-password'),
  userDisabled('user-disabled'),
  unknown(),
  ;

  const SignInAuthFailure([this.code]);
  final String? code;
}

enum SignUpAuthFailure {
  network('network-request-failed'),
  emailAlreadyInUse('email-already-in-use'),
  invalidEmail('invalid-email'),
  weakPassword('weak-password'),
  unknown(),
  ;

  const SignUpAuthFailure([this.code]);
  final String? code;
}
