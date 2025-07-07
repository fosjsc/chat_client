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
            : Center(
                child: Text(
                  controller.error ?? 'Has error',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
      ),
    );
  }
}
