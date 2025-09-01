import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/game_page.dart';

/// 應用程式入口點
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 新接龍應用
/// 負責應用程式的基本配置和路由
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '新新接龍',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'NotoSansTC',
      ),
      home: const GamePage(),
    );
  }
}
