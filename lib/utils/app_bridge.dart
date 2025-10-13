import 'dart:async';

class AppBridge {
  static final StreamController<void> _exitController =
      StreamController<void>.broadcast();

  static Stream<void> get onExitToMain => _exitController.stream;

  static void exitToMain() {
    if (!_exitController.isClosed) {
      _exitController.add(null);
    }
  }

  // Không bao giờ close controller, trừ khi app thật sự shutdown
  static void dispose() {
    if (!_exitController.isClosed) {
      _exitController.close();
    }
  }
}
