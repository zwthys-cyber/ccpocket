import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/messages.dart';
import '../../settings/state/settings_cubit.dart';
import '../../settings/state/settings_state.dart';
import '../state/chat_session_cubit.dart';
import '../state/chat_session_state.dart';

Future<void> showChatDisplayModeSheet(BuildContext context, String sessionId) {
  final settings = context.read<SettingsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => BlocProvider.value(
      value: settings,
      child: _DisplayModeSheet(sessionId: sessionId),
    ),
  );
}

class _DisplayModeSheet extends StatelessWidget {
  const _DisplayModeSheet({required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsCubit>();
    final selected = settings.state.sessionLiteModes[sessionId];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l.chatDisplayMode,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final option in <(bool?, String, String)>[
            (
              null,
              '${l.followDefaultMode} (${settings.state.liteMode ? l.liteMode : l.standardMode})',
              'default',
            ),
            (false, l.standardMode, 'standard'),
            (true, l.liteMode, 'lite'),
          ])
            ListTile(
              key: ValueKey('display_mode_${option.$3}'),
              title: Text(option.$2),
              trailing: selected == option.$1 ? const Icon(Icons.check) : null,
              onTap: () {
                settings.setSessionLiteMode(sessionId, option.$1);
                Navigator.pop(context);
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.liteModeDescription),
          ),
        ],
      ),
    );
  }
}

/// Live activity is kept outside the transcript so its clock never reflows it.
class SessionActivityBar extends StatelessWidget {
  const SessionActivityBar({
    super.key,
    required this.sessionId,
    this.isConnected = true,
  });

  final String sessionId;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SettingsCubit, SettingsState, bool>(
      selector: (state) => state.liteModeForSession(sessionId),
      builder: (context, liteMode) =>
          BlocSelector<ChatSessionCubit, ChatSessionState, (ProcessStatus, bool)>(
            selector: (state) =>
                (state.status, state.approval is! ApprovalNone),
            builder: (context, activity) {
              final (status, hasApproval) = activity;
              if (!liteMode &&
                  (!isConnected ||
                      hasApproval ||
                      status == ProcessStatus.idle ||
                      status == ProcessStatus.waitingApproval)) {
                return const SizedBox.shrink();
              }
              return _ActivityStatus(
                status: status,
                liteMode: liteMode,
                hasApproval: hasApproval,
              );
            },
          ),
    );
  }
}

class _ActivityStatus extends StatefulWidget {
  const _ActivityStatus({
    required this.status,
    required this.liteMode,
    required this.hasApproval,
  });

  final ProcessStatus status;
  final bool liteMode;
  final bool hasApproval;

  @override
  State<_ActivityStatus> createState() => _ActivityStatusState();
}

class _ActivityStatusState extends State<_ActivityStatus> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(covariant _ActivityStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _updateTimer();
  }

  void _updateTimer() {
    _timer?.cancel();
    _timer = widget.status == ProcessStatus.idle
        ? null
        : Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatSessionCubit>();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = widget.status;
    final active = status != ProcessStatus.idle;
    final label = switch (status) {
      ProcessStatus.running => l.liteModeRunning,
      ProcessStatus.starting => l.liteModeStarting,
      ProcessStatus.compacting => l.liteModeCompacting,
      ProcessStatus.waitingApproval => l.liteModeWaiting,
      ProcessStatus.idle => l.liteModeIdle,
    };
    final now = DateTime.now();
    final observedSince = cubit.activityObservedSince;
    final lastActivity = cubit.lastAgentActivityAt;
    final tool = status == ProcessStatus.running ? cubit.latestActivityTool : null;
    final details = [
      if (tool != null && tool.summary.isNotEmpty)
        '${tool.name} · ${tool.summary}'
      else if (tool != null)
        tool.name,
      if (active && observedSince != null)
        l.liteModeObserved(formatLiteModeDuration(now.difference(observedSince), l)),
      if (active && lastActivity != null)
        l.liteModeLastActivity(formatLiteModeDuration(now.difference(lastActivity), l)),
    ].join(' · ');

    return Padding(
      key: ValueKey(
        widget.liteMode
            ? 'lite_mode_activity_indicator'
            : 'session_activity_indicator',
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        2,
        12,
        6 + (widget.hasApproval ? MediaQuery.paddingOf(context).bottom : 0),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.liteMode ? colors.surfaceContainer : colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                widget.liteMode ? Icons.bolt_outlined : Icons.sensors_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: details.isEmpty ? label : '$label · $details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (details.isNotEmpty)
                        Text(
                          details,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.liteMode && !cubit.supportsPerformanceMode)
                        Text(
                          l.performanceModeBridgeUpdate,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uses at most two adjacent units, including for multi-day goal sessions.
String formatLiteModeDuration(Duration duration, AppLocalizations l) {
  final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  if (seconds < 60) return l.liteModeDurationSeconds(seconds);
  if (seconds < 3600) {
    return l.liteModeDurationMinutes(seconds ~/ 60, seconds % 60);
  }
  if (seconds < 86400) {
    return l.liteModeDurationHours(seconds ~/ 3600, seconds ~/ 60 % 60);
  }
  return l.liteModeDurationDays(seconds ~/ 86400, seconds ~/ 3600 % 24);
}
