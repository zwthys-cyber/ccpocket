import 'package:ccpocket/features/chat_session/widgets/status_line.dart';
import 'package:ccpocket/l10n/app_localizations.dart';
import 'package:ccpocket/models/messages.dart';
import 'package:ccpocket/theme/app_theme.dart';
import 'package:ccpocket/widgets/bubbles/streaming_bubble.dart';
import 'package:ccpocket/widgets/bubbles/thinking_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('active chat settles when Reduce Motion is enabled during a reply', (
    tester,
  ) async {
    Future<void> showChat({required bool reduceMotion}) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: const Scaffold(
          body: Column(children: [
            StatusLine(status: ProcessStatus.running),
            StreamingBubble(text: '正文'),
            ThinkingBubble(thinking: '第一行\n第二行', isStreaming: true),
          ]),
        ),
      ),
    );

    await showChat(reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    await showChat(reduceMotion: true);
    await tester.pumpAndSettle();
    expect(find.text('正文'), findsOneWidget);
    expect(find.text('思考中…'), findsOneWidget);
    expect(find.text('2 行'), findsOneWidget);
    final cursor = find.ancestor(of: find.text('▍'), matching: find.byType(Opacity));
    expect(tester.widget<Opacity>(cursor.first).opacity, 1);

    await showChat(reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });
}
