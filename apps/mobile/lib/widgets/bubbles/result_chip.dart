import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../features/file_peek/file_path_syntax.dart';
import '../../features/file_peek/markdown_link_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../models/messages.dart';
import '../../providers/bridge_cubits.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../theme/markdown_style.dart';
import '../link_hover_underline.dart';

class ResultChip extends StatelessWidget {
  final ResultMessage message;
  final FilePathTapCallback? onFileTap;
  final bool showSuccessResultText;

  const ResultChip({
    super.key,
    required this.message,
    this.onFileTap,
    this.showSuccessResultText = false,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final fileSuffixes = onFileTap != null
        ? FilePathSyntax.cachedSuffixSet(context.watch<FileListCubit>().state)
        : const <String>{};
    // Success text is a fallback when its assistant message is missing.
    final resultText = message.result;
    final showResultText =
        (message.subtype != 'success' || showSuccessResultText) &&
        resultText != null &&
        resultText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showResultText)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: AppSpacing.bubbleMarginV,
                horizontal: AppSpacing.bubbleMarginH,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.bubblePaddingV,
                horizontal: AppSpacing.bubblePaddingH,
              ),
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width *
                    AppSpacing.maxBubbleWidthFraction,
              ),
              decoration: BoxDecoration(
                color: appColors.assistantBubble,
                borderRadius: AppSpacing.assistantBubbleBorderRadius,
              ),
              child: LinkHoverUnderline(
                child: MarkdownBody(
                  data: resultText,
                  selectable: true,
                  styleSheet: buildMarkdownStyle(context),
                  onTapLink: buildChatMarkdownLinkHandler(
                    context,
                    onFileTap: onFileTap,
                    knownPathSuffixes: fileSuffixes,
                  ),
                  inlineSyntaxes: [
                    if (onFileTap != null) ...[
                      FilePathSyntax(knownPathSuffixes: fileSuffixes),
                      BareFilePathSyntax(knownPathSuffixes: fileSuffixes),
                    ],
                    ...colorCodeInlineSyntaxes,
                    ...localhostAutolinkInlineSyntaxes,
                  ],
                  builders: {
                    if (onFileTap != null)
                      'filePath': FilePathBuilder(onTap: onFileTap),
                    ...markdownBuilders,
                  },
                ),
              ),
            ),
          ),
        _TurnResultSummary(message: message),
      ],
    );
  }
}

class _TurnResultSummary extends StatelessWidget {
  const _TurnResultSummary({required this.message});

  final ResultMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;
    final l = AppLocalizations.of(context);
    final (label, icon, foreground, background) = switch (message.subtype) {
      'success' when message.stopReason == 'max_tokens' => (
        l.chatResultTruncated,
        Icons.info_outline,
        appColors.warningText,
        appColors.warningBubble,
      ),
      'success' => (
        l.done,
        Icons.check_circle_outline,
        appColors.statusOnline,
        appColors.successChip,
      ),
      'stopped' => (
        l.chatResultStopped,
        Icons.stop_circle_outlined,
        colors.onSurfaceVariant,
        colors.surfaceContainer,
      ),
      _ => (
        l.chatResultFailed,
        Icons.error_outline,
        appColors.errorText,
        appColors.errorChip,
      ),
    };
    final metrics = [
      if (message.duration case final duration?)
        '${(duration / 1000).toStringAsFixed(1)}s',
      if (message.toolCalls case final count? when count > 0)
        l.chatResultToolCalls(count),
      if (message.fileEdits case final count? when count > 0)
        l.chatResultFileEdits(count),
      if (message.cost case final cost?) '\$${cost.toStringAsFixed(4)}',
      if (message.inputTokens != null || message.outputTokens != null)
        '${message.inputTokens ?? 0}in/${message.outputTokens ?? 0}out tok',
      if (message.cachedInputTokens case final count? when count > 0)
        '$count cached',
    ];

    return Padding(
      key: const ValueKey('turn_result_summary'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.bubbleMarginH,
        vertical: 6,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: foreground),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (final metric in metrics)
                    Text(
                      metric,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (message.error case final error? when error.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SelectableText(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
