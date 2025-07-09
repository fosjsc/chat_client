import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_embedded/chat_embedded.dart';
import 'package:fluffychat/pages/auto_login/auto_login.dart';
import 'package:fluffychat/widgets/layouts/empty_page.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/share_scaffold_dialog.dart';

abstract class AppRoutes {
  static FutureOr<String?> embeddedLoggedOutRedirect(
    BuildContext context,
    GoRouterState state,
  ) {
    final clients = Matrix.of(context).widget.clients;
    final data = AppConfig.getDataByViewId(context);
    for (final client in clients) {
      if (client.isLogged() && client.userID != null && client.userID == data?['username']) {
        Matrix.of(context).setActiveClient(client);
        return null; // User is logged in, no redirect needed
      }
    }

    return '/auto-login';
  }

  AppRoutes();
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/',
      redirect: (context, state) {
        final data = AppConfig.getDataByViewId(context);
        return Matrix.of(context).widget.clients.any((client) => client.isLogged())
            ? '/rooms-embedded/${data?['room_id']}'
            : '/auto-login';
      },
    ),
    GoRoute(
      path: '/auto-login',
      pageBuilder: (context, state) => defaultPageBuilder(
        context,
        state,
        const AutoLogin(),
      ),
    ),
    ShellRoute(
      pageBuilder: (context, state, child) => noTransitionPageBuilder(
        context,
        state,
        child,
      ),
      routes: [
        GoRoute(
          path: '/rooms-embedded',
          redirect: embeddedLoggedOutRedirect,
          pageBuilder: (context, state) => defaultPageBuilder(
            context,
            state,
            const EmptyPage(),
          ),
          routes: [
            GoRoute(
              path: ':roomid',
              pageBuilder: (context, state) {
                final body = state.uri.queryParameters['body'];
                var shareItems = state.extra is List<ShareItem> ? state.extra as List<ShareItem> : null;
                if (body != null && body.isNotEmpty) {
                  shareItems ??= [];
                  shareItems.add(TextShareItem(body));
                }
                return defaultPageBuilder(
                  context,
                  state,
                  ChatEmbeddedPage(
                    roomId: state.pathParameters['roomid']!,
                    shareItems: shareItems,
                    eventId: state.uri.queryParameters['event'],
                  ),
                );
              },
              redirect: embeddedLoggedOutRedirect,
            ),
          ],
        ),
      ],
    ),
  ];

  static Page noTransitionPageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) =>
      NoTransitionPage(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: child,
      );

  static Page defaultPageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) =>
      FluffyThemes.isColumnMode(context)
          ? noTransitionPageBuilder(context, state, child)
          : MaterialPage(
              key: state.pageKey,
              restorationId: state.pageKey.value,
              child: child,
            );
}
