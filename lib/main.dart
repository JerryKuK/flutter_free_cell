import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain/entities/card.dart' as domain;
import 'presentation/providers/game_provider.dart';
import 'presentation/widgets/foundation_pile.dart';
import 'presentation/widgets/free_cell.dart';
import 'presentation/widgets/game_column.dart';

// 歷史記錄狀態管理
final historyNotifierProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<GameRecord>>>((ref) {
  return HistoryNotifier();
});

// 歷史記錄狀態管理類
class HistoryNotifier extends StateNotifier<AsyncValue<List<GameRecord>>> {
  HistoryNotifier() : super(const AsyncValue.loading()) {
    _loadGameHistory();
  }

  // 加載歷史記錄
  Future<void> _loadGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('game_history') ?? [];

      final history = historyJson
          .map((json) => GameRecord.fromJson(jsonDecode(json)))
          .toList();
      // 按日期排序，最新的在前面
      history.sort((a, b) => b.date.compareTo(a.date));

      state = AsyncValue.data(history);
    } catch (e) {
      developer.log('加載歷史記錄失敗: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 按不同方式排序歷史記錄
  Future<List<GameRecord>> getSortedHistory(int sortMethod) async {
    final historyData = state.value ?? [];
    List<GameRecord> sortedList = List.from(historyData);

    switch (sortMethod) {
      case 0: // 按日期
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 1: // 按時間
        sortedList.sort((a, b) {
          int timeCompare = a.duration.compareTo(b.duration);
          return timeCompare != 0 ? timeCompare : a.moves.compareTo(b.moves);
        });
        break;
      case 2: // 按移動次數
        sortedList.sort((a, b) {
          int movesCompare = a.moves.compareTo(b.moves);
          if (movesCompare != 0) return movesCompare;

          int timeCompare = a.duration.compareTo(b.duration);
          if (timeCompare != 0) return timeCompare;

          // 如果移動次數和完成時間都相同，則按最新日期排序（降序）
          return b.date.compareTo(a.date);
        });
        break;
    }

    return sortedList;
  }

  // 清空歷史記錄
  Future<void> clearGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('game_history');
      state = const AsyncValue.data([]);
    } catch (e) {
      developer.log('清除歷史記錄失敗: $e');
    }
  }

  // 添加遊戲記錄
  Future<void> addGameRecord(GameRecord record) async {
    try {
      final currentHistory = state.value ?? [];
      final updatedHistory = [record, ...currentHistory];

      // 保持記錄不超過20條
      if (updatedHistory.length > 20) {
        updatedHistory.removeLast();
      }

      // 更新狀態
      state = AsyncValue.data(updatedHistory);

      // 保存到 SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          updatedHistory.map((record) => jsonEncode(record.toJson())).toList();
      await prefs.setStringList('game_history', historyJson);
    } catch (e) {
      developer.log('添加遊戲記錄失敗: $e');
    }
  }
}

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

  // 歷史記錄
  List<GameRecord> gameHistory = [];

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
    _dealCards();
    startTime = DateTime.now();
  }

  // 加載歷史記錄
  Future<void> _loadGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('game_history') ?? [];

      setState(() {
        gameHistory = historyJson
            .map((json) => GameRecord.fromJson(jsonDecode(json)))
            .toList();
        // 按日期排序，最新的在前面
        gameHistory.sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e) {
      developer.log('加載歷史記錄失敗: $e');
    }
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

  // 顯示歷史記錄對話框
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Consumer(
          builder: (context, ref, child) {
            // 用於歷史記錄的狀態管理
            final historyAsyncValue = ref.watch(historyNotifierProvider);

            return historyAsyncValue.when(
              data: (history) {
                if (history.isEmpty) {
                  return AlertDialog(
                    title: const Text('遊戲記錄'),
                    content: const Text('暫無遊戲記錄'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('關閉'),
                      ),
                    ],
                  );
                }

                // 默認排序方式：按日期（最新在前）
                int sortMethod = 0;
                List<GameRecord> sortedHistory = List.from(history);
                sortedHistory.sort((a, b) => b.date.compareTo(a.date));

                // 使用 StatefulBuilder 以在對話框內管理狀態
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('遊戲記錄'),
                      contentPadding: const EdgeInsets.all(16),
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 400,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 排序選項
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment<int>(
                                  value: 0,
                                  label: Text('按日期'),
                                ),
                                ButtonSegment<int>(
                                  value: 1,
                                  label: Text('按時間'),
                                ),
                                ButtonSegment<int>(
                                  value: 2,
                                  label: Text('按移動'),
                                ),
                              ],
                              selected: {sortMethod},
                              onSelectionChanged: (Set<int> selection) {
                                setState(() {
                                  sortMethod = selection.first;
                                  // 使用異步方法獲取排序後的歷史記錄
                                  ref
                                      .read(historyNotifierProvider.notifier)
                                      .getSortedHistory(sortMethod)
                                      .then((value) {
                                    setState(() {
                                      sortedHistory = value;
                                    });
                                  });
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            // 歷史記錄列表
                            Expanded(
                              child: sortedHistory.isEmpty
                                  ? const Center(child: Text('暫無歷史記錄'))
                                  : Builder(builder: (context) {
                                      final ScrollController scrollController =
                                          ScrollController();
                                      return MouseRegion(
                                        cursor: SystemMouseCursors.basic,
                                        child: Scrollbar(
                                          controller: scrollController,
                                          thumbVisibility: true,
                                          trackVisibility: true,
                                          child: ListView.builder(
                                            controller: scrollController,
                                            itemCount: sortedHistory.length,
                                            itemExtent: 80,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            itemBuilder: (context, index) {
                                              final record =
                                                  sortedHistory[index];
                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 2,
                                                      offset:
                                                          const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        _getRecordColor(
                                                            index, sortMethod),
                                                    child: Text('${index + 1}'),
                                                  ),
                                                  title: Text(
                                                    '${record.date.year}/${record.date.month}/${record.date.day} ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                                                  ),
                                                  subtitle: Text(
                                                    '移動: ${record.moves} | 時間: ${record.duration.inMinutes}分${record.duration.inSeconds % 60}秒',
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                            ),
                            // 按鈕行
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(historyNotifierProvider.notifier)
                                        .clearGameHistory();
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('清除記錄'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('關閉'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => AlertDialog(
                title: const Text('加載錯誤'),
                content: Text('無法加載歷史記錄: $error'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('關閉'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  // 根據排名獲取顏色
  Color _getRecordColor(int index, int sortMethod) {
    // 只有排序方式不是默認時才使用特殊顏色
    if (sortMethod == 0 || index > 2) {
      return Colors.blue;
    }

    // 前三名用不同顏色
    switch (index) {
      case 0:
        return Colors.amber; // 金色
      case 1:
        return Colors.grey.shade400; // 銀色
      case 2:
        return Colors.brown.shade300; // 銅色
      default:
        return Colors.blue;
    }
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
                onPressed: _showHistoryDialog,
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

// 添加遊戲記錄類
class GameRecord {
  final DateTime date;
  final int moves;
  final Duration duration;

  GameRecord({
    required this.date,
    required this.moves,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'moves': moves,
      'duration': duration.inSeconds,
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      date: DateTime.parse(json['date']),
      moves: json['moves'],
      duration: Duration(seconds: json['duration']),
    );
  }
}
