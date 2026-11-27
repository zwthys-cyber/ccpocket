import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:ccpocket/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

final previewKey = GlobalKey();
bool get after => Platform.environment['PREVIEW_VARIANT'] == 'after';

Future<void> preparePreview(WidgetTester tester) async {
  const locale = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN');
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 874);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.runAsync(() async {
    for (final (family, path) in [
      ('PreviewSC', Platform.environment['PREVIEW_FONT']!),
      ('Roboto', Platform.environment['PREVIEW_FONT']!),
      ('MaterialIcons', 'assets/fonts/icons/CCPocketIcons.otf'),
    ]) {
      final loader = FontLoader(family);
      loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
      await loader.load();
    }
  });
}

ThemeData previewTheme() {
  final theme = AppTheme.lightThemeForLocale(const Locale('zh'));
  final text = theme.textTheme.apply(fontFamily: 'PreviewSC');
  return theme.copyWith(
    platform: TargetPlatform.iOS,
    textTheme: text,
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'PreviewSC'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'PreviewSC'),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
      hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(fontFamily: 'PreviewSC'),
    ),
  );
}

Widget previewBoundary(BuildContext context, Widget? child) =>
    RepaintBoundary(key: previewKey, child: child);

Future<void> savePreview(WidgetTester tester, String name, {bool unmount = true}) async {
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final boundary = previewKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = (await image.toByteData(format: ImageByteFormat.png))!;
    final file = File("${Platform.environment['PREVIEW_OUTPUT']}/${Platform.environment['PREVIEW_VARIANT']}-$name.png");
    file.writeAsBytesSync(png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes));
    image.dispose();
  });
  if (unmount) await tester.pumpWidget(const SizedBox.shrink());
}
