import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/entities/card.dart' as domain;
import 'presentation/providers/game_provider.dart';
import 'presentation/widgets/foundation_pile.dart';
import 'presentation/widgets/free_cell.dart';
import 'presentation/widgets/game_column.dart';

void main() {
  // 包裝整個應用於 ProviderScope 中
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// 新接龍應用
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '新接龍',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'NotoSansTC',
      ),
      home: const FreeCellGameScreen(title: '新接龍'),
    );
  }
}

/// 新接龍遊戲頁面
class FreeCellGameScreen extends StatefulWidget {
  final String title;

  const FreeCellGameScreen({super.key, required this.title});

  @override
  State<FreeCellGameScreen> createState() => _FreeCellGameScreenState();
}

class _FreeCellGameScreenState extends State<FreeCellGameScreen> {
  // 牌的花色 (紅桃、方塊、黑桃、梅花)
  static const List<String> suits = ['♥', '♦', '♠', '♣'];
  // 牌的點數
  static const List<String> ranks = [
    'A',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K'
  ];

  // 遊戲區域
  List<List<domain.PlayingCard>> columns =
      List.generate(8, (_) => []); // 8列主遊戲區
  List<domain.PlayingCard?> freeCells =
      List.generate(4, (_) => null); // 4個自由單元格
  List<List<domain.PlayingCard>> foundations =
      List.generate(4, (_) => []); // 4個基礎堆

  domain.PlayingCard? selectedCard;
  int? selectedColumnIndex;
  bool? selectedFromFreeCell;
  int? selectedCardIndex;
  bool selectedFromFoundation = false; // 新增：標記牌是否來自基礎堆

  // 遊戲統計
  int moves = 0;
  DateTime? startTime;

  @override
  void initState() {
    super.initState();
    _dealCards();
    startTime = DateTime.now();
  }

  // 發牌
  void _dealCards() {
    List<domain.PlayingCard> deck = [];

    // 創建一副完整的牌
    for (String suit in suits) {
      for (int i = 0; i < ranks.length; i++) {
        deck.add(domain.PlayingCard(
          suit: suit,
          rank: ranks[i],
          value: i + 1, // A=1, ..., K=13
          isRed: suit == '♥' || suit == '♦',
        ));
      }
    }

    // 洗牌
    deck.shuffle(Random());

    // 按列發牌
    for (int i = 0; i < deck.length; i++) {
      columns[i % 8].add(deck[i]);
    }
  }

  // 顯示幫助對話框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('遊戲規則'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('目標', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('將所有52張牌按花色和順序移動到右上角的四個基礎堆中。'),
                SizedBox(height: 8),
                Text('移動規則', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• 可以將任意頂部牌移到空的自由單元格。'),
                Text('• 可以將牌移到基礎堆，但必須從A開始，按花色遞增順序。'),
                Text('• 可以將牌移到其他列的頂部，但必須遵循顏色交替和遞減順序。'),
                Text('• 可以移動整個有效序列，前提是有足夠的空位。'),
                SizedBox(height: 8),
                Text('提示', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• 有效序列：不同顏色的卡片按遞減順序排列。'),
                Text('• 可移動的牌數 = 空自由單元格數 + 空列數 + 1。'),
                Text('• 點擊牌選中它，然後點擊目標位置移動它。'),
                Text('• 使用"自動回收"按鈕，自動將符合條件的牌移到基礎堆。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('了解'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 來監聽 GameNotifier
    return Consumer(
      builder: (context, ref, child) {
        final gameState = ref.watch(gameNotifierProvider);
        final gameNotifier = ref.read(gameNotifierProvider.notifier);

        // 設置上下文，用於顯示完成對話框等
        gameNotifier.setContext(context);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              // 顯示移動次數
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('移動: ${gameState.moveCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              // 添加自動回收按鈕
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => gameNotifier.autoCollect(),
                tooltip: '自動回收可移動的牌',
              ),
              // 添加查看歷史按鈕
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => gameNotifier.showHistoryDialog(),
                tooltip: '查看歷史記錄',
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: _showHelpDialog,
                tooltip: '幫助',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => gameNotifier.startNewGame(),
                tooltip: '重新開始',
              ),
            ],
          ),
          body: Column(
            children: [
              // 上方區域：自由單元格和基礎堆
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // 自由單元格
                    Expanded(
                      child: Row(
                        children: List.generate(4, (index) {
                          return Expanded(
                            child: FreeCellWidget(
                              card: gameState.freeCells[index],
                              index: index,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 基礎堆
                    Expanded(
                      child: Row(
                        children: List.generate(4, (index) {
                          return Expanded(
                            child: FoundationPileWidget(
                              pile: gameState.foundation[index],
                              index: index,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              // 遊戲區域
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: List.generate(8, (columnIndex) {
                      return GameColumnWidget(
                        column: gameState.columns[columnIndex],
                        columnIndex: columnIndex,
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
