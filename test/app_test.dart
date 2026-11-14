import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bozkurtlar/app_controller.dart';
import 'package:bozkurtlar/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('BozkurtlarSans');
    for (final weight in ['Regular', 'Medium', 'Bold', 'Black']) {
      text.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
    }
    await text.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('empty state does not show fabricated live measurements', (
    tester,
  ) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = AppController();
    await tester.pumpWidget(
      BozkurtlarApp(controller: model, initialize: false),
    );
    expect(find.text('Deneyap Kart 1A · Bağlı değil'), findsOneWidget);
    expect(find.text('Ham sensör değeri'), findsOneWidget);
    expect(find.text('DEMO MODU · Tüm değerler örnektir.'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
  testWidgets('demo dashboard and research navigation fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = AppController();
    await model.startDemo(at: DateTime(2026, 11, 14, 12));
    model.research =
        (jsonDecode(await rootBundle.loadString('assets/research.json'))
                as List)
            .cast<Map<String, dynamic>>();
    await tester.pumpWidget(
      BozkurtlarApp(controller: model, initialize: false),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('DEMO MODU · Tüm değerler örnektir.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Bilim'));
    await tester.pumpAndSettle();
    expect(find.text('Bilgiyle kök sal.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Doğru veri, doğru başlangıç.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
  testWidgets('dashboard design preview', (tester) async {
    tester.view.physicalSize = const Size(430, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = AppController();
    await model.startDemo(at: DateTime(2026, 11, 14, 12));
    await tester.pumpWidget(
      BozkurtlarApp(controller: model, initialize: false),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Home),
      matchesGoldenFile('goldens/dashboard.png'),
    );
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
