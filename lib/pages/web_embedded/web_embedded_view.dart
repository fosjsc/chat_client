import 'package:fluffychat/pages/web_embedded/web_embedded.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:flutter/material.dart';

class WebEmbeddedView extends StatelessWidget {
  final WebEmbeddedController controller;
  const WebEmbeddedView({super.key, required this.controller});

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
