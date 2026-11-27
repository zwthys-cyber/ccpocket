import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../l10n/app_localizations.dart';
import '../../models/messages.dart';
import '../../providers/bridge_cubits.dart';
import '../../services/bridge_service.dart';
import '../../widgets/workspace_pane_chrome.dart';
import '../session_list/workspace_shell_screen.dart';
import 'widgets/gallery_content.dart';
import 'widgets/gallery_empty_state.dart';

@RoutePage()
class GalleryScreen extends HookWidget {
  final String? sessionId;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  const GalleryScreen({
    super.key,
    this.sessionId,
    this.embedded = false,
    this.onBack,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isSessionMode = sessionId != null;
    final bridge = context.read<BridgeService>();
    final scopedGalleryStream = useMemoized(
      () => bridge.galleryStreamFor(sessionId: sessionId),
      [bridge, sessionId],
    );
    final scopedGallerySnapshot = useStream(
      scopedGalleryStream,
      initialData: bridge.galleryImagesFor(sessionId: sessionId),
      preserveState: false,
    );
    final shell = WorkspaceShellScreen.maybeOf(context);
    final chrome = resolveWorkspacePaneChrome(
      platform: Theme.of(context).platform,
      isAdaptiveWorkspace: shell != null && !shell.isSinglePane,
      isLeftPaneVisible: shell?.isLeftPaneVisible ?? false,
      slot: embedded && sessionId == null
          ? WorkspacePaneSlot.center
          : WorkspacePaneSlot.right,
    );

    final attempt = useState(0);
    final connection = useStream(
      useMemoized(() => bridge.connectionStatus, [bridge]),
      initialData: bridge.isConnected
          ? BridgeConnectionState.connected
          : bridge.currentBridgeConnectionState,
    );
    final online = connection.data == BridgeConnectionState.connected;
    final request = useMemoized(
      () => online
          ? bridge.requestGallery(sessionId: sessionId)
          : Future.value(GalleryLoadResult.offline),
      [bridge, sessionId, online, attempt.value],
    );
    final load = useFuture(request, preserveState: false);
    final result = load.connectionState == ConnectionState.done
        ? load.data
        : null;
    void retry() {
      if (!online) bridge.ensureConnected();
      attempt.value++;
    }

    final globalImages = context.watch<GalleryCubit>().state;
    final images = isSessionMode
        ? scopedGallerySnapshot.data ?? const []
        : globalImages.isNotEmpty
        ? globalImages
        : bridge.galleryImages;
    final leading = onBack != null
        ? IconButton(
            key: const ValueKey('embedded_gallery_back_button'),
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            style: chrome.useMacOSAdaptiveChrome
                ? chrome.compactButtonStyle()
                : null,
            icon: const Icon(Icons.arrow_back),
          )
        : null;

    return Scaffold(
      appBar: chrome.wrapAppBar(
        AppBar(
          toolbarHeight: chrome.toolbarHeight,
          automaticallyImplyLeading: !embedded,
          leading: chrome.wrapLeading(leading),
          leadingWidth: chrome.resolveLeadingWidth(
            hasLeading: leading != null,
            baseWidth: chrome.useMacOSAdaptiveChrome
                ? kWorkspaceMacOSToolbarLeadingSlotWidth
                : kToolbarHeight,
          ),
          titleSpacing: chrome.resolveTitleSpacing(hasLeading: leading != null),
          title: chrome.wrapTitle(
            Text(
              images.isEmpty
                  ? AppLocalizations.of(context).gallery
                  : AppLocalizations.of(context)
                        .galleryWithCount(images.length),
            ),
          ),
          actions: chrome.padActions([
            if (embedded && onClose != null)
              IconButton(
                key: const ValueKey('embedded_gallery_close_button'),
                onPressed: onClose,
                style: chrome.useMacOSAdaptiveChrome
                    ? chrome.compactButtonStyle()
                    : null,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
              ),
          ]),
        ),
      ),
      body: Column(
        children: [
          if (result == null)
            if (images.isEmpty)
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: AppLocalizations.of(context).galleryLoading,
                  ),
                ),
              )
            else
              LinearProgressIndicator(
                semanticsLabel: AppLocalizations.of(context).galleryLoading,
              ),
          if (result != null && result != GalleryLoadResult.loaded)
            if (images.isEmpty)
              Expanded(
                child: Center(
                  child: _GalleryRetry(result: result, retry: retry),
                ),
              )
            else
              _GalleryRetry(result: result, retry: retry),
          if (images.isEmpty && result == GalleryLoadResult.loaded)
            Expanded(child: GalleryEmptyState(isSessionMode: isSessionMode)),
          if (images.isNotEmpty)
            Expanded(
              child: GalleryContent(
                key: ValueKey((bridge, sessionId)),
                images: images,
                isSessionMode: isSessionMode,
                httpBaseUrl: bridge.httpBaseUrl ?? '',
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryRetry extends StatelessWidget {
  const _GalleryRetry({required this.result, required this.retry});

  final GalleryLoadResult result;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final message = switch (result) {
      GalleryLoadResult.offline => l.galleryOffline,
      GalleryLoadResult.timedOut => l.galleryTimedOut,
      _ => l.galleryLoadFailed,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: Text(l.retry)),
        ],
      ),
    );
  }
}
