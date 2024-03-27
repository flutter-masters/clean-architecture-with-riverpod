import '../entities/app_user.dart';
import '../entities/friendship.dart';
import '../failures/failure.dart';
import 'result.dart';

typedef Json = Map<String, dynamic>;
typedef FutureAuthResult<T, E> = Future<Result<T, E>>;
typedef FutureResult<T> = Future<Result<T, Failure>>;
typedef FriendshipsData = ({AppUser user, Friendship? friendship});
