import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_provider.dart';
import '../widgets/foundation_pile.dart';
import '../widgets/free_cell.dart';
import '../widgets/game_column.dart';
import '../widgets/history_dialog.dart';

/// 遊戲頁面
/// 顯示遊戲介面並處理用戶互動
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    developer.log('GamePage 重建，移動次數: ${gameState.moveCount}');

    // 將BuildContext設置到GameNotifier中
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameNotifierProvider.notifier).setContext(context);
      developer.log('設置 BuildContext 到 GameNotifier 完成');
    });

    // 手動檢查基礎堆狀態
    for (int i = 0; i < gameState.foundation.length; i++) {
      developer.log('UI重繪時：基礎堆 $i 包含 ${gameState.foundation[i].length} 張卡片');
      if (gameState.foundation[i].isNotEmpty) {
        developer.log('頂部卡片是：${gameState.foundation[i].last}');
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('新接龍'),
        actions: [
          // 顯示移動次數
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '移動: ${gameState.moveCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // 自動回收按鈕
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {
              developer.log('點擊自動回收按鈕');
              final notifier = ref.read(gameNotifierProvider.notifier);
              notifier.autoCollect();

              // 強制UI更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                developer.log('強制UI刷新後檢查基礎堆狀態');
                final currentState = ref.read(gameNotifierProvider);
                for (int i = 0; i < currentState.foundation.length; i++) {
                  developer.log(
                      '刷新後：基礎堆 $i 包含 ${currentState.foundation[i].length} 張卡片');
                }
              });
            },
            tooltip: '自動回收牌',
          ),
          // 歷史記錄按鈕
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
            tooltip: '歷史記錄',
          ),
          // 幫助按鈕
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: '幫助',
          ),
          // 重新開始按鈕
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(gameNotifierProvider.notifier).startNewGame(),
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
                    children: List.generate(
                      gameState.freeCells.length,
                      (index) => Expanded(
                        child: FreeCellWidget(
                          card: gameState.freeCells[index],
                          index: index,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 基礎堆
                Expanded(
                  child: Row(
                    children: List.generate(
                      gameState.foundation.length,
                      (index) => Expanded(
                        child: FoundationPileWidget(
                          pile: gameState.foundation[index],
                          index: index,
                          key: ValueKey(
                              'foundation_${index}_${gameState.foundation[index].length}'),
                        ),
                      ),
                    ),
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
                children: List.generate(
                  gameState.columns.length,
                  (index) => GameColumnWidget(
                    column: gameState.columns[index],
                    columnIndex: index,
                    key: ValueKey(
                        'column_${index}_${gameState.columns[index].length}'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示歷史記錄對話框
  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const HistoryDialog(),
    );
  }

  /// 顯示幫助對話框
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('遊戲規則'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新接龍是一種使用一副標準撲克牌的紙牌遊戲。'),
              SizedBox(height: 10),
              Text('遊戲目標：'),
              Text('將所有牌按花色和順序（從A到K）移到右上角的四個基礎堆。'),
              SizedBox(height: 10),
              Text('遊戲規則：'),
              Text('1. 遊戲區域分為8列主遊戲區、4個自由單元格和4個基礎堆。'),
              Text('2. 只能移動列頂部的牌。'),
              Text('3. 在主遊戲區，牌必須按照顏色交替（紅黑）和降序排列。'),
              Text('4. 自由單元格一次只能放置一張牌。'),
              Text('5. 基礎堆必須按照同一花色的升序排列，從A開始。'),
              Text('6. 可以選擇連續的不同顏色的牌作為一組移動。'),
              Text('7. 可以從基礎堆取回牌，但要謹慎使用此功能。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解了'),
          ),
        ],
      ),
    );
  }
}
