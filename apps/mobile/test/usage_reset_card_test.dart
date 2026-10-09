import 'dart:async';
import 'dart:convert';

import 'package:ccpocket/features/settings/widgets/usage_reset_card.dart';
import 'package:ccpocket/l10n/app_localizations.dart';
import 'package:ccpocket/models/messages.dart';
import 'package:ccpocket/services/bridge_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Bridge extends BridgeService {
  final events = StreamController<ServerMessage>.broadcast();
  final connections = StreamController<BridgeConnectionState>.broadcast();
  final sent = <Map<String, dynamic>>[];
  String? outcome;
  Completer<void> refreshed = Completer<void>();

  @override
  bool get isConnected => true;
  @override
  String? get lastUrl => 'ws://127.0.0.1:8765';
  @override
  Stream<ServerMessage> get messages => events.stream;
  @override
  Stream<BridgeConnectionState> get connectionStatus => connections.stream;
  @override
  void send(ClientMessage message) {
    final json = jsonDecode(message.toJson()) as Map<String, dynamic>;
    sent.add(json);
    events.add(UsageResetResultMessage(
      requestId: json['requestId'] as String,
      outcome: outcome,
      error: outcome == null ? 'Timeout' : null,
    ));
  }
  @override
  void dispose() {
    events.close();
    connections.close();
    super.dispose();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, _Bridge bridge, UsageResetCredits? credits, {VoidCallback? refresh}) async {
    bridge.refreshed = Completer<void>();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: UsageResetCard(
        credits: credits,
        bridgeService: bridge,
        onRefresh: () {
          if (!bridge.refreshed.isCompleted) bridge.refreshed.complete();
          refresh?.call();
        },
      )),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester, _Bridge bridge) async {
    await tester.tap(find.widgetWithText(FilledButton, '使用重置次数'));
    // The fake response stream belongs to the widget test's clock. Pump that
    // clock while the action is pending instead of waiting in runAsync, which
    // cannot drain the stream's queued events.
    for (var frame = 0; frame < 100 && !bridge.refreshed.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(bridge.refreshed.isCompleted, isTrue,
        reason: 'The mocked reset must complete and refresh usage.');
    await tester.pumpAndSettle();
  }

  testWidgets('uses the authoritative count without inventing detail rows', (tester) async {
    final bridge = _Bridge();
    addTearDown(bridge.dispose);
    await pump(tester, bridge, const UsageResetCredits(availableCount: 3));
    expect(find.text('可用重置机会：3 次'), findsOneWidget);
    expect(find.text('使用重置次数'), findsOneWidget);
    expect(bridge.sent, isEmpty);
  });

  testWidgets('requires confirmation and refreshes after redemption', (tester) async {
    final bridge = _Bridge()..outcome = 'reset';
    addTearDown(bridge.dispose);
    var refreshes = 0;
    await pump(tester, bridge, const UsageResetCredits(availableCount: 3), refresh: () => refreshes++);
    await tester.tap(find.text('使用重置次数'));
    await tester.pumpAndSettle();
    expect(bridge.sent, isEmpty);
    await confirm(tester, bridge);
    expect(bridge.sent.single['type'], 'consume_usage_reset');
    expect(bridge.sent.single['creditId'], isNull);
    expect(refreshes, 1);
  });

  testWidgets('reuses uncertain attempts after rebuilding the card', (tester) async {
    final bridge = _Bridge();
    addTearDown(bridge.dispose);
    const credits = UsageResetCredits(availableCount: 3);
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.pumpWidget(const SizedBox());
      await pump(tester, bridge, credits);
      await tester.tap(find.text('使用重置次数'));
      await tester.pumpAndSettle();
      await confirm(tester, bridge);
    }
    expect(bridge.sent, hasLength(2));
    expect(bridge.sent[0]['idempotencyKey'], bridge.sent[1]['idempotencyKey']);
    expect(bridge.sent[0]['requestId'], isNot(bridge.sent[1]['requestId']));
  });

  testWidgets('does not treat missing account support as zero opportunities', (tester) async {
    final bridge = _Bridge();
    addTearDown(bridge.dispose);
    await pump(tester, bridge, null);
    expect(find.textContaining('暂未获取重置机会信息'), findsOneWidget);
    expect(find.text('使用重置次数'), findsNothing);
  });

  testWidgets('preserves a count-only target when a retry gains credit details', (tester) async {
    final bridge = _Bridge();
    addTearDown(bridge.dispose);
    await pump(tester, bridge, const UsageResetCredits(availableCount: 3));
    await tester.tap(find.text('使用重置次数'));
    await tester.pumpAndSettle();
    await confirm(tester, bridge);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, bridge, const UsageResetCredits(
      availableCount: 2,
      credits: [UsageResetCredit(id: 'credit-2', resetType: 'codexRateLimits', status: 'available')],
    ));
    await tester.tap(find.text('使用重置次数'));
    await tester.pumpAndSettle();
    await confirm(tester, bridge);
    expect(bridge.sent[0]['idempotencyKey'], bridge.sent[1]['idempotencyKey']);
    expect(bridge.sent[1]['creditId'], isNull);
  });
}
