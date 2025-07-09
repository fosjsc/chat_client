import 'dart:ui' as ui;

import 'package:fluffychat/pages/chat/chat_app_bar_list_tile.dart';
import 'package:fluffychat/pages/chat_embedded/chat_embedded.dart';
import 'package:fluffychat/pages/chat_embedded/chat_emoji_picker_embedded.dart';
import 'package:fluffychat/pages/chat_embedded/chat_event_list_embedded.dart';
import 'package:fluffychat/pages/chat_embedded/chat_input_row.dart';
import 'package:fluffychat/pages/chat_embedded/pinned_events_embedded.dart';
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

enum _EventContextAction { info, report }

class ChatEmbeddedView extends StatelessWidget {
  final ChatEmbeddedController controller;

  const ChatEmbeddedView(this.controller, {super.key});

  List<Widget> _appBarActions(BuildContext context) {
    if (controller.selectMode) {
      return [
        if (controller.canEditSelectedEvents)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: L10n.of(context).edit,
            onPressed: controller.editSelectedEventAction,
          ),
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: L10n.of(context).copy,
          onPressed: controller.copyEventsAction,
        ),
        if (controller.canPinSelectedEvents)
          IconButton(
            icon: const Icon(Icons.push_pin_outlined),
            onPressed: controller.pinEvent,
            tooltip: L10n.of(context).pinMessage,
          ),
        if (controller.canRedactSelectedEvents)
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: L10n.of(context).redactMessage,
            onPressed: controller.redactEventsAction,
          ),
        if (controller.selectedEvents.length == 1)
          PopupMenuButton<_EventContextAction>(
            useRootNavigator: true,
            onSelected: (action) {
              switch (action) {
                case _EventContextAction.info:
                  controller.showEventInfo();
                  controller.clearSelectedEvents();
                  break;
                case _EventContextAction.report:
                  controller.reportEventAction();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (controller.canSaveSelectedEvent)
                PopupMenuItem(
                  onTap: () => controller.saveSelectedEvent(context),
                  value: null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download_outlined),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).downloadFile),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: _EventContextAction.info,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outlined),
                    const SizedBox(width: 12),
                    Text(L10n.of(context).messageInfo),
                  ],
                ),
              ),
              if (controller.selectedEvents.single.status.isSent)
                PopupMenuItem(
                  value: _EventContextAction.report,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(L10n.of(context).reportMessage),
                    ],
                  ),
                ),
            ],
          ),
      ];
    }
    return [];
  }

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
    final scrollUpBannerEventId = controller.scrollUpBannerEventId;

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
            var appbarBottomHeight = 0.0;
            if (controller.room.pinnedEventIds.isNotEmpty) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            if (scrollUpBannerEventId != null) {
              appbarBottomHeight += ChatAppBarListTile.fixedHeight;
            }
            return Scaffold(
              appBar: AppBar(
                toolbarHeight: controller.selectMode ? null : 0,
                actionsIconTheme: IconThemeData(
                  color: controller.selectedEvents.isEmpty ? null : theme.colorScheme.onTertiaryContainer,
                ),
                backgroundColor: controller.selectedEvents.isEmpty ? null : theme.colorScheme.primary,
                automaticallyImplyLeading: false,
                leading: controller.selectMode
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.clearSelectedEvents,
                        tooltip: L10n.of(context).close,
                        color: theme.colorScheme.onTertiaryContainer,
                      )
                    : null,
                actions: _appBarActions(context),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(appbarBottomHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PinnedEventsEmbedded(controller),
                      if (scrollUpBannerEventId != null)
                        ChatAppBarListTile(
                          leading: IconButton(
                            color: theme.colorScheme.onSurfaceVariant,
                            icon: const Icon(Icons.close),
                            tooltip: L10n.of(context).close,
                            onPressed: () {
                              controller.discardScrollUpBannerEventId();
                              controller.setReadMarker();
                            },
                          ),
                          title: L10n.of(context).jumpToLastReadMessage,
                          trailing: TextButton(
                            onPressed: () {
                              controller.scrollToEventId(
                                scrollUpBannerEventId,
                              );
                              controller.discardScrollUpBannerEventId();
                            },
                            child: Text(L10n.of(context).jump),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
                                    ? theme.colorScheme.primary
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
