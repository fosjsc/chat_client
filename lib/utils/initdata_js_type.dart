import 'dart:js_interop';

@JS()
@staticInterop
class InitialData {}

extension InitialDataExtension on InitialData {
  external String get username;
  external String get password;
  external String get homeserver_url;
  external String get room_id;
}
