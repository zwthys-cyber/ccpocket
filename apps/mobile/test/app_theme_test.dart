import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ccpocket/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps action and status text readable in both themes', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppColors>()!;
      final pairs = [
        (scheme.onPrimary, scheme.primary, 'primary action'),
        (scheme.onPrimaryContainer, scheme.primaryContainer, 'selected chip'),
        (scheme.onSurfaceVariant, scheme.surface, 'secondary text'),
        (scheme.outline, scheme.surfaceContainerHigh, 'search hint'),
        (colors.statusRunning, scheme.surfaceContainerHigh, 'running status'),
        (colors.statusApproval, colors.approvalBar, 'approval status'),
        (colors.userBubbleText, colors.userBubble, 'user message'),
      ];
      for (final (foreground, background, label) in pairs) {
        final luminances = [
          foreground.computeLuminance(),
          background.computeLuminance(),
        ]..sort();
        final contrast = (luminances.last + 0.05) / (luminances.first + 0.05);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness} $label',
        );
      }
    }
  });

  group('AppTheme font fallback', () {
    test('applies Chinese system font fallback only for zh locale', () {
      final zhFallback = AppTheme.lightThemeForLocale(const Locale('zh'))
          .textTheme
          .bodyMedium
          ?.fontFamilyFallback;

      _expectChineseFallback(zhFallback);

      for (final locale in [
        null,
        const Locale('en'),
        const Locale('ja'),
        const Locale('ko'),
      ]) {
        final fallback = AppTheme.lightThemeForLocale(locale)
            .textTheme
            .bodyMedium
            ?.fontFamilyFallback;
        _expectNoChineseFallback(fallback, reason: 'locale=$locale');
      }
    });
  });
}

void _expectChineseFallback(List<String>? fallback) {
  expect(
    fallback,
    containsAll(['Microsoft YaHei', 'PingFang SC', 'Noto Sans CJK SC']),
  );
}

void _expectNoChineseFallback(
  List<String>? fallback, {
  required String reason,
}) {
  for (final family in ['Microsoft YaHei', 'PingFang SC', 'Noto Sans CJK SC']) {
    expect(
      fallback ?? const <String>[],
      isNot(contains(family)),
      reason: reason,
    );
  }
}
