"""Construct runner-only capture tests from the checked-out app's test harnesses."""
import os
from pathlib import Path
import shutil

root = Path(__file__).resolve().parent
test = Path("test")
shutil.copyfile(root / "support.dart", test / "zh_preview_support.dart")
shared = "import 'zh_preview_support.dart';\n"


def replace_once(source, old, new):
    if source.count(old) != 1:
        raise ValueError(f"Expected one harness marker {old!r}")
    return source.replace(old, new, 1)


def harness(filename, dest, marker, case, extras=""):
    source = (test / filename).read_text()
    source = replace_once(source, marker, case + "\n" + marker)
    source = replace_once(source, "child: MaterialApp(", """child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: previewBoundary,""")
    source = source.replace("locale: const Locale('en'),", "locale: const Locale('zh'),")
    if "theme: AppTheme.darkTheme," in source:
        source = replace_once(source, "theme: AppTheme.darkTheme,", "theme: previewTheme(),")
    else:
        source = replace_once(source, "builder: previewBoundary,", "builder: previewBoundary,\n        theme: previewTheme(),")
    if filename == "home_content_skeleton_test.dart":
        source = replace_once(source, "home: Scaffold(", """home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: CustomScrollView(
              physics: const NeverScrollableScrollPhysics(),
              slivers: [SessionListSliverAppBar(
                bridgeLabel: '演示工作站',
                onTitleTap: () {},
                onDisconnect: () {},
                onOpenSettings: () {},
                onOpenGallery: () {},
                isConnected: true,
              )],
            ),
          ),""")
    (test / dest).write_text(shared + extras + source)


harness("home_content_skeleton_test.dart", "zh_home_preview_test.dart",
        "  group('HomeContent skeleton', () {", """
  testWidgets('capture Chinese preview home', (tester) async {
    await preparePreview(tester);
    final activity = DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String();
    final today = DateTime.now().toIso8601String();
    await tester.pumpWidget(_buildHomeContent(
      sessions: [SessionInfo(
        id: 'demo-active', name: '整理项目文档', provider: 'codex',
        projectPath: '/demo/notes', status: 'running', createdAt: activity,
        lastActivityAt: activity, lastMessage: '正在核对目录和示例。',
        codexApprovalPolicy: 'never', codexSandboxMode: 'danger-full-access',
        codexModel: 'gpt-6.2-sol', codexModelReasoningEffort: 'high',
      )],
      recentSessions: [RecentSession(
        sessionId: 'demo-recent', provider: 'codex', name: '更新阅读列表',
        projectPath: '/demo/notes', isSidechain: false, created: today, modified: today,
        firstPrompt: '整理本周阅读笔记，按主题归类。', gitBranch: 'main',
      )],
      cubit: cubit, draftService: draftService, revenueCatService: revenueCatService,
      supportBannerService: supportBannerService,
    ));
    await tester.pump();
    expect(find.text('整理项目文档'), findsWidgets);
    expect(find.text(after ? '按项目分组' : 'Grouped'), findsWidgets);
    await savePreview(tester, 'home');
  });
""", "import 'package:ccpocket/features/session_list/widgets/session_list_app_bar.dart';\n")

harness("settings_usage_visibility_test.dart", "zh_theme_preview_test.dart",
        "  group('Settings usage visibility', () {", """
  testWidgets('capture Chinese preview theme', (tester) async {
    await preparePreview(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = _SeededSettingsCubit(prefs, activeMachineId: 'demo');
    final machines = _StaticMachineManagerService([MachineWithStatus(
      machine: Machine(id: 'demo', name: '演示工作站', host: '127.0.0.1'),
      status: MachineStatus.online,
    )]);
    final manager = _createMachineManagerCubit(machines);
    final bridge = _FakeBridgeService(connected: true, fakeLastUrl: 'ws://localhost:8765');
    await tester.pumpWidget(await _buildScreen(bridge: bridge, settingsCubit: settings, machineManagerCubit: manager));
    await tester.pump();
    final context = tester.element(find.byType(SettingsScreen));
    unawaited(showThemeBottomSheet(context: context, current: ThemeMode.system, onChanged: (_) {}));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(after ? '深色' : 'Dark'), findsWidgets);
    await savePreview(tester, 'theme');
    await settings.close();
    await manager.close();
    machines.dispose();
    bridge.dispose();
  });
""", "import 'package:ccpocket/features/settings/widgets/theme_bottom_sheet.dart';\n")

# Inject the same scoped fetch timeout, including its pre-upgrade notification
# on the generic bridge error stream that GalleryScreen did not consume.
after = os.environ["PREVIEW_VARIANT"] == "after"
override = """
  @override
  Future<GalleryLoadResult> requestGallery({String? projectPath, String? sessionId}) async {
    return GalleryLoadResult.timedOut;
  }
""" if after else """
  @override
  void requestGallery({String? projectPath, String? sessionId}) {
    events.add(const ErrorMessage(message: 'Gallery did not load in time', errorCode: 'gallery_failed'));
  }
"""
(test / "zh_gallery_preview_test.dart").write_text(shared + """
import 'dart:async';
import 'package:ccpocket/features/gallery/gallery_screen.dart';
import 'package:ccpocket/l10n/app_localizations.dart';
import 'package:ccpocket/models/messages.dart';
import 'package:ccpocket/providers/bridge_cubits.dart';
import 'package:ccpocket/services/bridge_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TimedOutBridge extends BridgeService {
  final events = StreamController<ServerMessage>.broadcast();
  @override
  Stream<ServerMessage> get messages => events.stream;
  @override
  bool get isConnected => true;
""" + override + """
  @override
  void dispose() {
    events.close();
    super.dispose();
  }
}
void main() {
  testWidgets('capture Chinese preview gallery timeout', (tester) async {
    await preparePreview(tester);
    final bridge = _TimedOutBridge();
    final gallery = GalleryCubit(const <GalleryImage>[], bridge.galleryStream);
    await tester.pumpWidget(RepositoryProvider<BridgeService>.value(value: bridge,
      child: BlocProvider<GalleryCubit>.value(value: gallery,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'), theme: previewTheme(), builder: previewBoundary,
          debugShowCheckedModeBanner: false, home: const GalleryScreen(),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text(after ? 'Bridge 响应超时，请重试。' : '还没有截图'), findsOneWidget);
    await savePreview(tester, 'gallery');
    await gallery.close();
    bridge.dispose();
  });
}
""")
