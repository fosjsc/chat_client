import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/auto_login/auto_login.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';

class AutoLoginView extends StatelessWidget {
  final AutoLoginController controller;
  const AutoLoginView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: MaxWidthBody(
        child: controller.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : controller.error != null
                ? Center(
                    child: Text(
                      L10n.of(context).oopsSomethingWentWrong,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      "View AutoLogin",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
      ),
    );
  }
}
