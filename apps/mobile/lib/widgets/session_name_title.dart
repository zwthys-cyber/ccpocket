import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../l10n/app_localizations.dart';
import '../models/messages.dart';
import '../services/bridge_service.dart';
import '../theme/app_theme.dart';
import 'rename_session_dialog.dart';

/// Tappable session name in the AppBar. Shows session name or project name.
/// Tap to rename via dialog.
class SessionNameTitle extends StatelessWidget {
  final String sessionId;
  final String? projectPath;
  final SessionWorkspaceInfo? workspace;
  final String? branch;
  final Provider? provider;
  final ProcessStatus? status;

  const SessionNameTitle({
    super.key,
    required this.sessionId,
    this.projectPath,
    this.workspace,
    this.branch,
    this.provider,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bridge = context.read<BridgeService>();
    return StreamBuilder<ProjectsMessage>(
      stream: bridge.projectsStream,
      initialData: bridge.projectsState,
      builder: (context, projectsSnapshot) => StreamBuilder<List<SessionInfo>>(
        stream: bridge.sessionList,
        initialData: bridge.sessions,
        builder: (context, sessionsSnapshot) {
          final sessions = sessionsSnapshot.data ?? [];
          final session = sessions.where((s) => s.id == sessionId).firstOrNull;
          final name = session?.name;
          final effectiveWorkspace = session?.workspace ?? workspace;
          final currentProjectName = projectsSnapshot.data?.projects
              .where((project) => project.id == effectiveWorkspace?.projectId)
              .firstOrNull
              ?.name;
          final projectName = currentProjectName?.isNotEmpty == true
              ? currentProjectName!
              : effectiveWorkspace?.projectName;
          final fallback = projectName?.isNotEmpty == true
              ? projectName!
              : pathBasename(session?.projectPath ?? projectPath ?? '');
          final title = name?.trim() ?? '';
          final effectiveBranch =
              branch ?? session?.worktreeBranch ?? session?.gitBranch;
          final metadata = [
            if (title.isNotEmpty && fallback.isNotEmpty) fallback,
            if (effectiveBranch != null && effectiveBranch.isNotEmpty)
              effectiveBranch,
            if (provider case final agent?) agent.label,
          ].join(' · ');

          return GestureDetector(
            onTap: () async {
              final newName = await showRenameSessionDialog(
                context,
                currentName: name,
              );
              if (newName == null || !context.mounted) return;
              bridge.renameSession(
                sessionId: sessionId,
                name: newName.isEmpty ? null : newName,
              );
            },
            child: _SessionHeading(
              title: title.isNotEmpty ? title : fallback,
              metadata: metadata,
              status: status,
            ),
          );
        },
      ),
    );
  }
}

class _SessionHeading extends StatelessWidget {
  final String title;
  final String metadata;
  final ProcessStatus? status;

  const _SessionHeading({
    required this.title,
    required this.metadata,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final colors = theme.extension<AppColors>();
    final statusLabel = switch (status) {
      ProcessStatus.running ||
      ProcessStatus.starting ||
      ProcessStatus.compacting => l?.statusWorking,
      ProcessStatus.waitingApproval => l?.statusNeedsYou,
      _ => null,
    };
    final statusColor = status == ProcessStatus.waitingApproval
        ? colors?.statusApproval ?? theme.colorScheme.tertiary
        : colors?.statusRunning ?? theme.colorScheme.primary;
    final metadataStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        if (metadata.isNotEmpty || statusLabel != null)
          Text.rich(
            TextSpan(
              children: [
                if (statusLabel != null)
                  TextSpan(
                    text: statusLabel,
                    style: TextStyle(color: statusColor),
                  ),
                if (statusLabel != null && metadata.isNotEmpty)
                  const TextSpan(text: ' · '),
                TextSpan(text: metadata),
              ],
            ),
            style: metadataStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
