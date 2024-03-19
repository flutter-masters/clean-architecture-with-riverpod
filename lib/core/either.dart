sealed class Either<L, R> {}

class Left<L, R> extends Either<L, R> {
  Left(this.value);

  final L value;
}

class Right<L, R> extends Either<L, R> {
  Right(this.value);

  final R value;
}
