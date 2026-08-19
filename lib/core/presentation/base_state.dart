/// Minimal contract every screen's state class must satisfy so that
/// [BaseNotifier] and [BaseView] can handle loading/error generically
/// without knowing anything about the screen-specific fields.
abstract class BaseState {
  bool get isLoading;
  String? get errorMessage;
}
