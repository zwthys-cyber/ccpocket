Widget simulatedStatusBar(BuildContext context, Widget? child) {
  return RepaintBoundary(
    key: previewKey,
    child: Stack(
      fit: StackFit.expand,
      children: [
        child!,
        Positioned(
          top: 14, left: 26, right: 26, height: 22,
          child: IgnorePointer(
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: 'PreviewSC', fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
              child: Row(children: [
                const Text('18:13'),
                const Spacer(),
                const Text('5G'),
                const SizedBox(width: 5),
                DecoratedBox(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: const Color(0xff29583b)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('67', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    ),
  );
}

void registerSafeAreaCapture() {
  testWidgets('capture compact home status inset during scroll', (tester) async {
    const topInset = 59.0;
    print('CAPTURE_STEP font and viewport');
    await preparePreview(tester);
    tester.view.padding = const FakeViewPadding(top: topInset, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    print('CAPTURE_STEP services');
    final bridge = _MockBridgeService();
    print('CAPTURE_STEP settings');
    final settings = await _createSettingsCubit(bridge);
    print('CAPTURE_STEP mount home');
    await tester.pumpWidget(_buildWorkspaceApp(
      platform: TargetPlatform.iOS,
      locale: const Locale('zh'),
      bridge: bridge,
      settingsCubit: settings,
      draftService: DraftService(await SharedPreferences.getInstance()),
      revenueCatService: _FakeRevenueCatService(),
      supportBannerService: await _createSupportBannerService(),
      debugRecentSessions: List.generate(28, (index) => RecentSession(
        sessionId: 'recent-$index', name: '整理阅读笔记 $index',
        firstPrompt: '整理本周的阅读笔记。', projectPath: '/demo/project-$index',
        provider: 'codex', gitBranch: 'main', created: '2026-11-27T09:00:00Z', modified: '2026-11-27T09:15:00Z',
        isSidechain: false,
      )),
      adaptiveHome: true,
    ));
    await _pumpUi(tester);
    print('CAPTURE_STEP seed');
    bridge.emitSessions([SessionInfo(
      name: '整理项目文档', id: 'synthetic-active', provider: 'codex', projectPath: '/demo/notes',
      createdAt: '2026-11-27T08:00:00Z', lastActivityAt: '2026-11-27T09:00:00Z',
      status: 'idle', lastMessage: '正在核对目录与示例。',
    )]);
    await _pumpUi(tester);
    print('CAPTURE_STEP measure expanded');
    final search = find.byKey(const ValueKey('search_field'));
    final action = find.byKey(const ValueKey('new_session_button'));
    final nested = tester.state<NestedScrollViewState>(find.byType(NestedScrollView).first);
    expect(search, findsOneWidget);
    expect(action, findsOneWidget);
    final initial = tester.getTopLeft(search).dy;
    expect(initial, greaterThan(topInset));
    print('CAPTURE_STEP capture expanded');
    await savePreview(tester, 'expanded', unmount: false);

    print('CAPTURE_STEP collapse');
    final maximum = nested.outerController.position.maxScrollExtent;
    expect(maximum, greaterThan(0));
    nested.outerController.jumpTo(maximum);
    await _pumpUi(tester);
    final collapsed = tester.getTopLeft(search).dy;
    final collapsedAction = tester.getTopLeft(action).dy;
    print('SAFE_AREA top=$topInset initial=$initial collapsedSearch=$collapsed collapsedAction=$collapsedAction scroll=$maximum');
    print('CAPTURE_STEP capture collapsed');
    await savePreview(tester, 'collapsed', unmount: false);
    if (after) {
      expect(collapsed, greaterThanOrEqualTo(topInset));
      expect(collapsedAction, greaterThanOrEqualTo(topInset));
    } else {
      expect(collapsed, lessThan(topInset));
      expect(collapsedAction, lessThan(topInset));
    }
    nested.outerController.jumpTo(0);
    await _pumpUi(tester);
    expect(tester.getTopLeft(search).dy, closeTo(initial, 0.1));
    await tester.pumpWidget(const SizedBox.shrink());
    print('CAPTURE_STEP teardown');
    // Unmounting the shell pauses its platform-event subscriptions. Leave
    // service cleanup outside the widget tester's synthetic clock.
    unawaited(settings.close());
    await tester.pump();
    print('CAPTURE_STEP complete');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
