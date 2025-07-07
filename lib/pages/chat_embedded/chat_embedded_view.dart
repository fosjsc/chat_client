import 'dart:ui' as ui;

import 'package:fluffychat/pages/chat_embedded/chat_embedded.dart';
import 'package:fluffychat/pages/chat_embedded/chat_emoji_picker_embedded.dart';
import 'package:fluffychat/pages/chat_embedded/chat_event_list_embedded.dart';
import 'package:fluffychat/pages/chat_embedded/chat_input_row.dart';
import 'package:fluffychat/pages/chat_embedded/reply_display_embedded.dart';
import 'package:flutter/material.dart';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/utils/account_config.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import '../../utils/stream_extension.dart';


class ChatEmbeddedView extends StatelessWidget {
  final ChatEmbeddedController controller;

  const ChatEmbeddedView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (controller.room.membership == Membership.invite) {
      showFutureLoadingDialog(
        context: context,
        future: () => controller.room.join(),
        exceptionContext: ExceptionContext.joinRoom,
      );
    }
    final bottomSheetPadding = FluffyThemes.isColumnMode(context) ? 16.0 : 8.0;

    final accountConfig = Matrix.of(context).client.applicationAccountConfig;

    return PopScope(
      canPop: controller.selectedEvents.isEmpty && !controller.showEmojiPicker,
      onPopInvokedWithResult: (pop, _) async {
        if (pop) return;
        if (controller.selectedEvents.isNotEmpty) {
          controller.clearSelectedEvents();
        } else if (controller.showEmojiPicker) {
          controller.emojiPickerAction();
        }
      },
      child: StreamBuilder(
        stream: controller.room.client.onRoomState.stream
            .where((update) => update.roomId == controller.room.id)
            .rateLimit(const Duration(seconds: 1)),
        builder: (context, snapshot) => FutureBuilder(
          future: controller.loadTimelineFuture,
          builder: (BuildContext context, snapshot) {
            return Scaffold(
              body: DropTarget(
                onDragDone: controller.onDragDone,
                onDragEntered: controller.onDragEntered,
                onDragExited: controller.onDragExited,
                child: Stack(
                  children: <Widget>[
                    if (accountConfig.wallpaperUrl != null)
                      Opacity(
                        opacity: accountConfig.wallpaperOpacity ?? 0.5,
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: accountConfig.wallpaperBlur ?? 0.0,
                            sigmaY: accountConfig.wallpaperBlur ?? 0.0,
                          ),
                          child: MxcImage(
                            cacheKey: accountConfig.wallpaperUrl.toString(),
                            uri: accountConfig.wallpaperUrl,
                            fit: BoxFit.cover,
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            isThumbnail: false,
                            placeholder: (_) => Container(),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: GestureDetector(
                              onTap: controller.clearSingleSelectedEvent,
                              child: ChatEmbeddedEventList(controller: controller),
                            ),
                          ),
                          if (controller.showScrollDownButton)
                            Divider(
                              height: 1,
                              color: theme.dividerColor,
                            ),
                          if (controller.room.isExtinct)
                            Container(
                              margin: EdgeInsets.all(bottomSheetPadding),
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.chevron_right),
                                label: Text(L10n.of(context).enterNewChat),
                                onPressed: controller.goToNewRoomAction,
                              ),
                            )
                          else if (controller.room.canSendDefaultMessages &&
                              controller.room.membership == Membership.join)
                            Container(
                              margin: EdgeInsets.all(bottomSheetPadding),
                              constraints: const BoxConstraints(
                                maxWidth: FluffyThemes.maxTimelineWidth,
                              ),
                              alignment: Alignment.center,
                              child: Material(
                                clipBehavior: Clip.hardEdge,
                                color: controller.selectedEvents.isNotEmpty
                                    ? theme.colorScheme.tertiaryContainer
                                    : theme.colorScheme.surfaceContainerHigh,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(24),
                                ),
                                child: controller.room.isAbandonedDMRoom == true
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.all(
                                                16,
                                              ),
                                              foregroundColor: theme.colorScheme.error,
                                            ),
                                            icon: const Icon(
                                              Icons.archive_outlined,
                                            ),
                                            onPressed: controller.leaveChat,
                                            label: Text(
                                              L10n.of(context).leave,
                                            ),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.all(
                                                16,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.forum_outlined,
                                            ),
                                            onPressed: controller.recreateChat,
                                            label: Text(
                                              L10n.of(context).reopenChat,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ReplyDisplayEmbedded(controller),
                                          ChatInputRowEmbedded(controller),
                                          ChatEmojiPickerEmbedded(controller),
                                        ],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (controller.dragging)
                      Container(
                        color: theme.scaffoldBackgroundColor.withAlpha(230),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.upload_outlined,
                          size: 100,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
