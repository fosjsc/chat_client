import 'dart:js_interop';

@JS()
@staticInterop
class InitialData {}

extension InitialDataExtension on InitialData {
  external String get username;
  external String get password;
  external String get homeserver_url;
  external String get room_id;
  external String get pushGatewayUrl;
  external String get pushKey;
  external String get pushAppId;
  external bool get darkMode;
  external String get lang;
  external double get fontSizeFactor;

  toJson() {
    return {
      "username": username,
      "password": password,
      "homeserver_url": homeserver_url,
      "room_id": room_id,
      "pushGatewayUrl": pushGatewayUrl,
      "pushKey": pushKey,
      "pushAppId": pushAppId,
      "darkMode": darkMode,
      "lang": lang,
      "fontSizeFactor": fontSizeFactor,
    };
  }
}