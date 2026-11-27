import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Flutter identifies the host OS on native and web targets.
bool get followsDeviceLanguage =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;

Locale? displayLocaleOverride(String savedId) {
  if (followsDeviceLanguage || savedId.isEmpty) return null;
  final language = savedId.split(RegExp(r'[-_]')).first.toLowerCase();
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode == language) return locale;
  }
  return null;
}

Locale resolveDeviceLocale(List<Locale> preferences) =>
    basicLocaleListResolution(preferences, AppLocalizations.supportedLocales);
