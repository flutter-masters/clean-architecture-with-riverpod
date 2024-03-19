sealed class AuthFailure {}

class NetworkFailure extends AuthFailure {}

class CreateUserFailure extends AuthFailure {}

class UserNotFoundFailure extends AuthFailure {}

class EmailExistFailure extends AuthFailure {}

class WeakPasswordFailure extends AuthFailure {}

class InvalidEmailFailure extends AuthFailure {}

class InvalidCredentialsFailure extends AuthFailure {}

class UserDisableFailure extends AuthFailure {}

class UnknownFailure extends AuthFailure {}
