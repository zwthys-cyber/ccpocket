import '../models/messages.dart';
import 'app_localizations.dart';

extension SessionLabels on AppLocalizations {
  String codexPermissionsLabel(CodexPermissionsMode mode) => switch (mode) {
    CodexPermissionsMode.defaultPermissions => defaultPermissionsLabel,
    CodexPermissionsMode.autoReview => autoReviewModeLabel,
    CodexPermissionsMode.fullAccess => fullAccessLabel,
    CodexPermissionsMode.custom => customPermissionsLabel,
  };

  String claudePermissionLabel(PermissionMode mode) => switch (mode) {
    PermissionMode.defaultMode => defaultLabel,
    PermissionMode.auto => permissionAutoMode,
    PermissionMode.acceptEdits => permissionAcceptEditsMode,
    PermissionMode.plan => permissionPlanMode,
    PermissionMode.bypassPermissions => permissionBypassMode,
  };

  String sandboxMenuLabel(SandboxMode mode, {required bool isClaude}) =>
      switch ((mode, isClaude)) {
        (SandboxMode.on, true) => sandboxSafeMode,
        (SandboxMode.off, true) => sandboxStandard,
        (SandboxMode.on, false) => sandboxOnLabel,
        (SandboxMode.off, false) => sandboxOffLabel,
      };

  String reasoningLevel(ReasoningEffort effort) => switch (effort.value) {
    'none' => effortNoneLabel,
    'minimal' => effortMinimalLabel,
    'low' => effortLightLabel,
    'medium' => effortMediumLabel,
    'high' => effortHighLabel,
    'xhigh' => effortXHighLabel,
    'max' => effortMaxLabel,
    'ultra' => effortUltraLabel,
    _ => effort.label,
  };

  String claudeEffortLevel(ClaudeEffort effort) => switch (effort) {
    ClaudeEffort.low => effortLowLabel,
    ClaudeEffort.medium => effortMediumLabel,
    ClaudeEffort.high => effortHighLabel,
    ClaudeEffort.xhigh => effortClaudeXHighLabel,
    ClaudeEffort.max => effortMaxLabel,
  };

  String webSearchLabel(WebSearchMode mode) => switch (mode) {
    WebSearchMode.disabled => webSearchDisabled,
    WebSearchMode.cached => webSearchCached,
    WebSearchMode.live => webSearchLive,
  };
}
