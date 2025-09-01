import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/card.dart' as domain;
import '../../domain/entities/game_record.dart';
import '../../domain/entities/game_state.dart';
import '../providers/history_provider.dart';
import '../widgets/history_dialog.dart';
import 'providers.dart';

part 'game_provider.g.dart';

/// 遊戲狀態提供者
@riverpod
class GameNotifier extends _$GameNotifier {
  // 用於存儲全局BuildContext的引用，用於顯示SnackBar消息
  late BuildContext? _context;

  // 設置BuildContext
  void setContext(BuildContext context) {
    _context = context;
  }

  @override
  GameState build() {
    // 初始化遊戲狀態
    final startGameUseCase = ref.read(startGameUseCaseProvider);
    return startGameUseCase();
  }

  /// 開始新遊戲
  void startNewGame() {
    final startGameUseCase = ref.read(startGameUseCaseProvider);
    state = startGameUseCase();
  }

  /// 顯示歷史記錄對話框
  void showHistoryDialog() {
    if (_context == null) {
      developer.log('無法顯示歷史記錄對話框：context為空');
      return;
    }

    showDialog(
      context: _context!,
      builder: (context) => const HistoryDialog(),
    );
  }

  /// 選擇卡片
  void selectCard(domain.Card card, CardLocation location) {
    if (state.selectedCard == null) {
      // 如果沒有選中卡片，選擇當前卡片
      state = state.selectCard(card, location);
    } else {
      // 如果已經選中卡片，先檢查是否可以移動到基礎堆
      if (location.type == CardLocationType.foundation) {
        // 如果點擊的是基礎堆，嘗試移動卡片
        tryMoveCard(state.selectedCardLocation!, location);
      } else {
        // 否則，取消原有選擇並選擇新卡片
        state = state.clearSelection().selectCard(card, location);
      }
    }
  }

  /// 嘗試移動卡片
  void tryMoveCard(CardLocation from, CardLocation to) {
    try {
      final moveCardUseCase = ref.read(moveCardUseCaseProvider);
      final newState = moveCardUseCase(state, from, to);

      // 檢查遊戲是否完成
      if (newState.isGameCompleted && !state.isGameCompleted) {
        developer.log('遊戲完成！準備保存記錄...');
        state = newState; // 先更新狀態，這樣saveGameRecord才能獲取正確的狀態
        saveGameRecord().then((_) {
          developer.log('遊戲記錄已保存！');
          _showGameCompletedDialog();
        });
      } else {
        state = newState;
      }
    } catch (e) {
      // 移動失敗，取消選擇
      developer.log('移動失敗：$e');
      state = state.clearSelection();
    }
  }

  /// 取消選擇卡片
  void clearSelection() {
    state = state.clearSelection();
  }

  /// 自動收集卡片
  void autoCollect() {
    developer.log('開始自動收集卡片流程...');

    final autoCollectUseCase = ref.read(autoCollectUseCaseProvider);
    final result = autoCollectUseCase(state);

    // 顯示結果消息
    if (_context != null) {
      if (result.hasCollectedCards) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(
              '成功自動回收了 ${result.cardsCollected} 張卡片，移動次數：${result.state.moveCount}',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('沒有可以自動回收的牌'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    // 檢查遊戲是否完成
    if (result.state.isGameCompleted && !state.isGameCompleted) {
      developer.log('通過自動收集完成遊戲！準備保存記錄...');
      state = result.state; // 先更新狀態
      saveGameRecord().then((_) {
        developer.log('自動收集後的遊戲記錄已保存！');
        _showGameCompletedDialog();
      });
    } else {
      // 更新狀態
      state = result.state;
      developer.log('已更新遊戲狀態');
    }
  }

  /// 保存遊戲記錄
  Future<void> saveGameRecord() async {
    developer.log('嘗試保存遊戲記錄...');
    if (!state.isGameCompleted) {
      developer.log('遊戲未完成，不保存記錄');
      return;
    }

    if (state.endTime == null) {
      developer.log('遊戲結束時間為空，不保存記錄');
      return;
    }

    final duration = state.endTime!.difference(state.startTime);
    developer.log('遊戲持續時間：${duration.inMinutes}分${duration.inSeconds % 60}秒');
    developer.log('移動次數：${state.moveCount}');

    final record = GameRecord(
      date: DateTime.now(),
      moves: state.moveCount,
      duration: duration,
    );

    try {
      // 使用HistoryNotifier保存記錄
      await ref.read(historyNotifierProvider.notifier).saveGameRecord(record);
      developer.log('遊戲記錄保存成功！歷史記錄已更新');
    } catch (e) {
      developer.log('保存遊戲記錄時發生錯誤：$e');
    }
  }

  /// 顯示遊戲完成對話框
  void _showGameCompletedDialog() {
    if (_context == null) {
      developer.log('無法顯示遊戲完成對話框：context為空');
      return;
    }

    // 使用WidgetsBinding確保在UI更新後再顯示對話框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context == null) return;

      final duration = state.endTime!.difference(state.startTime);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      developer.log('顯示遊戲完成對話框，遊戲時間：$minutes分$seconds秒');

      // 保存當前context的引用
      final BuildContext currentContext = _context!;

      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('恭喜！遊戲完成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('移動次數：${state.moveCount}'),
              Text('遊戲時間：$minutes 分 $seconds 秒'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 先關閉對話框
                Navigator.of(dialogContext).pop();
                developer.log('使用者選擇開始新遊戲');
                // 確保對話框完全關閉後再開始新遊戲
                Future.delayed(const Duration(milliseconds: 300), () {
                  startNewGame();
                });
              },
              child: const Text('開始新遊戲'),
            ),
            TextButton(
              onPressed: () {
                // 只關閉對話框
                Navigator.of(dialogContext).pop();
                developer.log('使用者選擇關閉對話框');
              },
              child: const Text('關閉'),
            ),
          ],
        ),
      );
    });
  }
}
