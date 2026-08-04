import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_rescuers/core/branding/app_logo.dart';
import 'package:food_rescuers/core/theme/app_colors.dart';

void main() {
  group('launcher icon generation', () {
    Future<void> renderAndSave({
      required WidgetTester tester,
      required Widget child,
      required String filename,
      required Color? backgroundColor,
    }) async {
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundaryKey,
              child: Container(
                width: 1024,
                height: 1024,
                color: backgroundColor ?? Colors.transparent,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final boundary = boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = Directory('assets/icon');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      debugPrint('Generated: ${file.absolute.path}');
    }

    testWidgets('generates icon.png (legacy/iOS)', (tester) async {
      await renderAndSave(
        tester: tester,
        filename: 'icon.png',
        backgroundColor: AppColors.bgLight,
        child: const AppLogoMark(size: 1024 * 0.62),
      );

      expect(File('assets/icon/icon.png').existsSync(), isTrue);
    });

    testWidgets('generates icon_foreground.png (adaptive)', (tester) async {
      await renderAndSave(
        tester: tester,
        filename: 'icon_foreground.png',
        backgroundColor: null,
        child: const AppLogoMark(size: 1024 * 0.60),
      );

      expect(File('assets/icon/icon_foreground.png').existsSync(), isTrue);
    });

    testWidgets('generates icon_monochrome.png (themed)', (tester) async {
      await renderAndSave(
        tester: tester,
        filename: 'icon_monochrome.png',
        backgroundColor: null,
        child: const AppLogoMark(
          size: 1024 * 0.60,
          monochrome: true,
          color: Colors.black,
        ),
      );

      expect(File('assets/icon/icon_monochrome.png').existsSync(), isTrue);
    });
  });
}
