import 'dart:ui';

import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

abstract class AppConfig {
  static String _applicationName = 'fChat';

  static String get applicationName => _applicationName;
  static String? _applicationWelcomeMessage;

  static String? get applicationWelcomeMessage => _applicationWelcomeMessage;
  static String _defaultHomeserver = 'chat.fosjsc.com';
  static String? username;
  static String? password;

  static String get defaultHomeserver => _defaultHomeserver;
  static double fontSizeFactor = 1;
  static const Color chatColor = primaryColor;
  static Color? colorSchemeSeed = primaryColor;
  static const double messageFontSize = 16.0;
  static const bool allowOtherHomeservers = true;
  static const bool enableRegistration = true;
  static const Color primaryColor = Color(0xFF5625BA);
  static const Color primaryColorLight = Color(0xFFCCBDEA);
  static const Color secondaryColor = Color(0xFF41a2bc);
  static String _privacyUrl =
      'https://github.com/krille-chan/fluffychat/blob/main/PRIVACY.md';

  static const Set<String> defaultReactions = {'👍', '❤️', '😂', '😮', '😢'};

  static String get privacyUrl => _privacyUrl;
  static const String website = 'https://fluffychat.im';
  static const String enablePushTutorial =
      'https://github.com/krille-chan/fluffychat/wiki/Push-Notifications-without-Google-Services';
  static const String encryptionTutorial =
      'https://github.com/krille-chan/fluffychat/wiki/How-to-use-end-to-end-encryption-in-FluffyChat';
  static const String startChatTutorial =
      'https://github.com/krille-chan/fluffychat/wiki/How-to-Find-Users-in-FluffyChat';
  static const String appId = 'im.fluffychat.FluffyChat';
  static const String appOpenUrlScheme = 'im.fluffychat';
  static String _webBaseUrl = 'https://fluffychat.im/web';

  static String get webBaseUrl => _webBaseUrl;
  static const String sourceCodeUrl =
      'https://github.com/krille-chan/fluffychat';
  static const String supportUrl =
      'https://github.com/krille-chan/fluffychat/issues';
  static const String changelogUrl =
      'https://github.com/krille-chan/fluffychat/blob/main/CHANGELOG.md';
  static final Uri newIssueUrl = Uri(
    scheme: 'https',
    host: 'github.com',
    path: '/krille-chan/fluffychat/issues/new',
  );
  static bool renderHtml = true;
  static bool hideRedactedEvents = false;
  static bool hideUnknownEvents = true;
  static bool separateChatTypes = false;
  static bool autoplayImages = true;
  static bool sendTypingNotifications = true;
  static bool sendPublicReadReceipts = true;
  static bool swipeRightToLeftToReply = true;
  static bool? sendOnEnter;
  static bool showPresences = true;
  static bool displayNavigationRail = false;
  static bool experimentalVoip = false;
  static const bool hideTypingUsernames = false;
  static const String inviteLinkPrefix = 'https://matrix.to/#/';
  static const String deepLinkPrefix = 'im.fluffychat://chat/';
  static const String schemePrefix = 'matrix:';
  static const String pushNotificationsChannelId = 'fluffychat_push';
  static const String pushNotificationsAppId = 'chat.fluffy.fluffychat';
  static const double borderRadius = 18.0;
  static const double columnWidth = 360.0;
  static final Uri homeserverList = Uri(
    scheme: 'https',
    host: 'servers.joinmatrix.org',
    path: 'servers.json',
  );

  static void loadFromJson(Map<String, dynamic> json) {
    if (json['chat_color'] != null) {
      try {
        colorSchemeSeed = Color(json['chat_color']);
      } catch (e) {
        Logs().w(
          'Invalid color in config.json! Please make sure to define the color in this format: "0xffdd0000"',
          e,
        );
      }
    }
    if (json['application_name'] is String) {
      _applicationName = json['application_name'];
    }
    if (json['application_welcome_message'] is String) {
      _applicationWelcomeMessage = json['application_welcome_message'];
    }
    if (json['default_homeserver'] is String) {
      _defaultHomeserver = json['default_homeserver'];
    }
    if (json['privacy_url'] is String) {
      _privacyUrl = json['privacy_url'];
    }
    if (json['web_base_url'] is String) {
      _webBaseUrl = json['web_base_url'];
    }
    if (json['render_html'] is bool) {
      renderHtml = json['render_html'];
    }
    if (json['hide_redacted_events'] is bool) {
      hideRedactedEvents = json['hide_redacted_events'];
    }
    if (json['hide_unknown_events'] is bool) {
      hideUnknownEvents = json['hide_unknown_events'];
    }
  }

  static setInitData({
    String? homeServer,
    String? username,
    String? password,
  }) {
    _defaultHomeserver = homeServer ?? _defaultHomeserver;
    username = username;
    password = password;
  }

  static Future<void> checkHomeServerAction(BuildContext context) async {
    final homeServer = AppConfig.defaultHomeserver;
    final homeServerInput = homeServer.toLowerCase().replaceAll(' ', '-');

    try {
      var homeServer = Uri.parse(homeServerInput);

      if (homeServer.scheme.isEmpty) {
        homeServer = Uri.https(homeServerInput, '');
      }
      final client = await Matrix.of(context).getLoginClient();
      final (_, _, loginFlows) = await client.checkHomeserver(homeServer);

      if (loginFlows.isEmpty) {
        return;
      }
    } catch (e) {
      print('CheckHomeServer Exception: $e');
    }
  }

  static Future<void> loginAction({
    required String username,
    required String password,
    required BuildContext context,
  }) async {
    final matrix = Matrix.of(context);

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    try {
      final client = isClientLoggedIn(username, context);
      if (client != null) {
        matrix.setActiveClient(client);
      } else {
        AuthenticationIdentifier identifier;
        if (username.isEmail) {
          identifier = AuthenticationThirdPartyIdentifier(
            medium: 'email',
            address: username,
          );
        } else {
          identifier = AuthenticationUserIdentifier(user: username);
        }

        final client = await matrix.getLoginClient();

        await client.login(
          LoginType.mLoginPassword,
          identifier: identifier,
          // To stay compatible with older server versions
          // ignore: deprecated_member_use
          user: identifier.type == AuthenticationIdentifierTypes.userId
              ? username
              : null,
          password: password,
          initialDeviceDisplayName: PlatformInfos.clientName,
        );
      }
    } on MatrixException catch (exception) {
      print('Auto Login MatrixException: ${exception.errorMessage}');
      return;
    } catch (exception) {
      print('Auto Login Exception: $exception');
      return;
    }
  }

  static Client? isClientLoggedIn(String username, BuildContext context) {
    final clients = Matrix.of(context).widget.clients;

    for (final client in clients) {
      if (client.userID == username ||
          client.userID?.contains(username) == true) {
        if (client.isLogged()) {
          return client;
        } else {
          return null;
        }
      }
    }

    return null; // Không tìm thấy user
  }
}

extension on String {
  static final RegExp _emailRegex = RegExp(r'(.+)@(.+)\.(.+)');

  bool get isEmail => _emailRegex.hasMatch(this);
}
