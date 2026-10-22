import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oasx/ui/ui.dart';

void main() {
  testWidgets('AppButton 在 Material 平台渲染四种变体', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: const Color(0xff6750a4),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: '主要', variant: AppButtonVariant.primary),
              AppButton(label: '次要', variant: AppButtonVariant.secondary),
              AppButton(label: '描边', variant: AppButtonVariant.outline),
              AppButton(label: '文字', variant: AppButtonVariant.text),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('主要'), findsOneWidget);
    expect(find.text('次要'), findsOneWidget);
    expect(find.text('描边'), findsOneWidget);
    expect(find.text('文字'), findsOneWidget);
  });

  testWidgets('AppButton 禁用态不可点击', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: '禁用',
            onPressed: null,
          ),
        ),
      ),
    );
    await tester.tap(find.text('禁用'));
    expect(tapped, isFalse);
  });

  testWidgets('AppButton 点击回调正常', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: '点击',
            icon: Icons.check,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('点击'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('FluentPalette 深浅色取值不同', (tester) async {
    late FluentPalette light;
    late FluentPalette dark;

    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('light'),
      theme: ThemeData(brightness: Brightness.light),
      home: Builder(builder: (context) {
        light = FluentPalette.of(context);
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MaterialApp(
      key: const ValueKey('dark'),
      theme: ThemeData(brightness: Brightness.dark),
      home: Builder(builder: (context) {
        dark = FluentPalette.of(context);
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    expect(light.isDark, isFalse);
    expect(dark.isDark, isTrue);
    // 浅色卡片是白的，深色卡片是深的
    expect(light.card.computeLuminance(),
        greaterThan(dark.card.computeLuminance()));
  });
}
