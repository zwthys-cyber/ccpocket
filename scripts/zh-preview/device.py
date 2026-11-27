"""Prepare a CI-only integration test that uses the simulator's real system locale."""
from pathlib import Path

source = Path("test/settings_usage_visibility_test.dart").read_text().split("void main() {", 1)[0]
source = source.replace("import 'helpers/bridge_version_test_values.dart';",
                        "import '../test/helpers/bridge_version_test_values.dart';")
# Use the locale expression that the candidate actually passes to MaterialApp.router.
# It may use a top-level platform helper or a SettingsState getter.
main = Path("lib/main.dart").read_text()
if "locale: appLocale," not in main:
    raise ValueError("Review the candidate's MaterialApp locale resolution")
if "displayLocaleOverride(settings.appLocaleId)" not in main:
    raise ValueError("Review the new display locale helper used by CcpocketApp")
source = source.replace("  final screen = MultiRepositoryProvider(",
    "  final appLocale = displayLocaleOverride(settingsCubit.state.appLocaleId);\n  final screen = MultiRepositoryProvider(")
source = source.replace("        locale: const Locale('en'),",
                        """        locale: appLocale,
        theme: AppTheme.lightThemeForLocale(WidgetsBinding.instance.platformDispatcher.locale),
        debugShowCheckedModeBanner: false,""")
entry = Path("integration_test/zh_system_locale_test.dart")
entry.parent.mkdir(exist_ok=True)
imports = """import 'dart:io';
import 'package:ccpocket/theme/app_theme.dart';
import 'package:ccpocket/l10n/display_locale.dart';
import 'package:integration_test/integration_test.dart';
"""
entry.write_text(imports + source + """
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('iPhone settings follows the simulator language with an old preference', (tester) async {
    expect(Platform.isIOS, isTrue);
    final osLanguage = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    const expectedLanguage = String.fromEnvironment('PREVIEW_EXPECTED_LANGUAGE');
    expect(osLanguage, expectedLanguage);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_app_locale', 'ja');
    final settings = _SeededSettingsCubit(prefs, activeMachineId: 'demo');
    final machines = _StaticMachineManagerService([MachineWithStatus(
      machine: Machine(id: 'demo', name: 'Notes', host: '127.0.0.1'),
      status: MachineStatus.online,
    )]);
    final manager = _createMachineManagerCubit(machines);
    final bridge = _FakeBridgeService(connected: true, fakeLastUrl: 'ws://localhost:8765');
    await tester.pumpWidget(await _buildScreen(bridge: bridge, settingsCubit: settings, machineManagerCubit: manager));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(SettingsScreen));
    expect(Localizations.localeOf(context).languageCode, osLanguage);
    final l = AppLocalizations.of(context);
    expect(find.byKey(const ValueKey('settings_display_language')), findsNothing);
    expect(find.text(l.language), findsNothing);
    final themeTile = find.widgetWithText(ListTile, l.theme);
    expect(themeTile, findsOneWidget);
    await binding.takeScreenshot('ios-$osLanguage-settings');
    await tester.tap(themeTile);
    await tester.pumpAndSettle();
    expect(find.text(l.themeDark), findsOneWidget);
    await binding.takeScreenshot('ios-$osLanguage-theme');
    await tester.pumpWidget(const SizedBox.shrink());
    await settings.close();
    await manager.close();
    machines.dispose();
    bridge.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
""")
manifest = Path("pubspec.yaml")
text = manifest.read_text()
if "  integration_test:" not in text:
    manifest.write_text(text.replace("dev_dependencies:\n", "dev_dependencies:\n  integration_test:\n    sdk: flutter\n", 1))
driver = Path("test_driver/zh_system_locale_driver.dart")
driver.parent.mkdir(exist_ok=True)
driver.write_text("""
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (String name, List<int> data, [Map<String, Object?>? args]) async {
    final file = File('${Platform.environment["PREVIEW_OUTPUT"]}/$name.png');
    await file.writeAsBytes(data);
    return data.isNotEmpty;
  },
);
""")
