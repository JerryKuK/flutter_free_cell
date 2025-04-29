// 這是一個基本的 Flutter 小部件測試。
//
// 要與小部件進行交互，請使用 flutter_test 包中的 WidgetTester 工具。
// 例如，可以發送點擊和滾動手勢，也可以使用 WidgetTester 在小部件樹中查找子小部件，
// 讀取文本，並驗證小部件屬性的值是否正確。

import 'package:flutter/material.dart';
import 'package:flutter_free_cell/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('應用加載測試', (WidgetTester tester) async {
    // 構建我們的應用並觸發一個幀
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // 驗證應用標題是否正確
    expect(find.text('新接龍'), findsWidgets);

    // 驗證是否有遊戲元素出現
    expect(find.byType(AppBar), findsOneWidget);

    // 等待UI完全加載
    await tester.pump(const Duration(seconds: 1));

    // 驗證是否有基本遊戲功能按鈕
    expect(find.byIcon(Icons.refresh), findsOneWidget); // 查找重新開始按鈕
    expect(find.byIcon(Icons.history), findsOneWidget); // 查找歷史記錄按鈕
  });
}
