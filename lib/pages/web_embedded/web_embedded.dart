import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/web_embedded/web_embedded_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/tor_stub.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/fluffy_chat_app.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:matrix/matrix.dart';

class WebEmbedded extends StatefulWidget {
  const WebEmbedded({super.key});

  @override
  WebEmbeddedController createState() => WebEmbeddedController();
}

class WebEmbeddedController extends State<WebEmbedded> {
  String? error;
  List<LoginFlow>? loginFlows;

  bool isLoading = false;
  bool isTorBrowser = false;

  Future<void> _checkTorBrowser() async {
    if (!kIsWeb) return;

    Hive.openBox('test').then((value) => null).catchError(
      (e, s) async {
        await showOkAlertDialog(
          context: context,
          title: L10n.of(context).indexedDbErrorTitle,
          message: L10n.of(context).indexedDbErrorLong,
        );
        _checkTorBrowser();
      },
    );

    final isTor = await TorBrowserDetector.isTorBrowser;
    isTorBrowser = isTor;
  }

  Future<void> checkHomeServerAction() async {
    final homeServer = AppConfig.defaultHomeserver;
    final homeServerInput = homeServer?.toLowerCase().replaceAll(' ', '-');

    if (homeServerInput == null) {
      setState(() {
        error = L10n.of(context).oopsSomethingWentWrong;
        isLoading = false;
      });
      return;
    }

    setState(() {
      error = loginFlows = null;
      isLoading = true;
    });

    try {
      var homeServer = Uri.parse(homeServerInput);

      if (homeServer.scheme.isEmpty) {
        homeServer = Uri.https(homeServerInput, '');
      }
      final client = await Matrix.of(context).getLoginClient();
      final (_, _, loginFlows) = await client.checkHomeserver(homeServer);
      this.loginFlows = loginFlows;

      if (loginFlows.isEmpty) {
        setState(() {
          error = L10n.of(context).oopsSomethingWentWrong;
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(
        () => error = L10n.of(context).oopsSomethingWentWrong,
      );
    }
  }

  Future<void> loginAction() async {
    final matrix = Matrix.of(context);
    final username = AppConfig.username;
    final password = AppConfig.password;

    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      setState(
        () => error = L10n.of(context).oopsSomethingWentWrong,
      );
      return;
    }

    try {
      final AuthenticationIdentifier identifier = AuthenticationUserIdentifier(user: username);
      final client = await matrix.getLoginClient();

      await client.login(
        LoginType.mLoginPassword,
        identifier: identifier,
        // To stay compatible with older server versions
        // ignore: deprecated_member_use
        user: identifier.type == AuthenticationIdentifierTypes.userId ? username : null,
        password: password,
        initialDeviceDisplayName: PlatformInfos.clientName,
      );
    } on MatrixException catch (exception) {
      setState(() => error = exception.errorMessage);
      return setState(() => isLoading = false);
    } catch (exception) {
      setState(() => error = exception.toString());
      return setState(() => isLoading = false);
    }
  }

  Future<void> autoLoginAction() async {
    final clients = Matrix.of(context).widget.clients;

    for (final client in clients) {
      if (client.userID != null && client.userID == AppConfig.username) {
        Matrix.of(context).setActiveClient(client);
      }
    }

    final isLoggedIn = clients.any((client) {
      return client.isLogged() && client.userID == AppConfig.username;
    });

    if (isLoggedIn) {
      FluffyChatApp.router.go('/rooms-embedded/${AppConfig.toRoomId}');
    } else {
      await checkHomeServerAction();
      await loginAction();
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  void initState() {
    _checkTorBrowser();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await autoLoginAction();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WebEmbeddedView(controller: this);
  }
}
