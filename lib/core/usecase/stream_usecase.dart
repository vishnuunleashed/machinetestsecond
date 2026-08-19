/// Streaming counterpart to [UseCase] — for use cases that expose a
/// continuous feed (e.g. a reactive local-storage watch) rather than a
/// single Future result.
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}
