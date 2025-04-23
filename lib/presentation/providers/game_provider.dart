import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/card.dart' as domain;
import '../../domain/entities/game_record.dart';
import '../../domain/entities/game_state.dart';
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
      state = moveCardUseCase(state, from, to);

      // 檢查遊戲是否完成
      if (state.isGameCompleted) {
        saveGameRecord();
        _showGameCompletedDialog();
      }
    } catch (e) {
      // 移動失敗，取消選擇
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

    // 計算當前基礎堆中的卡片總數
    int oldFoundationCardCount = 0;
    for (int i = 0; i < state.foundation.length; i++) {
      oldFoundationCardCount += state.foundation[i].length;
      developer.log('自動收集前：基礎堆 $i 有 ${state.foundation[i].length} 張卡片');
      if (state.foundation[i].isNotEmpty) {
        developer.log('頂部卡片是：${state.foundation[i].last}');
      }
    }
    developer.log('自動收集前基礎堆總共有 $oldFoundationCardCount 張卡片');
    final oldMoveCount = state.moveCount;
    developer.log('當前移動次數：$oldMoveCount');

    final autoCollectUseCase = ref.read(autoCollectUseCaseProvider);
    final newState = autoCollectUseCase(state);

    // 計算更新後基礎堆中的卡片總數
    int newFoundationCardCount = 0;
    for (int i = 0; i < newState.foundation.length; i++) {
      newFoundationCardCount += newState.foundation[i].length;
      developer.log('自動收集後：基礎堆 $i 有 ${newState.foundation[i].length} 張卡片');
      if (newState.foundation[i].isNotEmpty) {
        developer.log('頂部卡片是：${newState.foundation[i].last}');
      }
    }
    developer.log('自動收集後基礎堆總共有 $newFoundationCardCount 張卡片');
    developer.log(
        '新的移動次數：${newState.moveCount}，增加了 ${newState.moveCount - oldMoveCount} 次');

    // 判斷是否有卡片被回收：檢查基礎堆卡片數量是否增加
    if (newFoundationCardCount > oldFoundationCardCount) {
      // 有卡片被回收
      final cardsCollected = newFoundationCardCount - oldFoundationCardCount;
      final movesAdded = newState.moveCount - oldMoveCount;
      developer.log('成功自動回收了 $cardsCollected 張卡片，增加了 $movesAdded 次移動');
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content:
                Text('成功自動回收了 $cardsCollected 張卡片，移動次數：${newState.moveCount}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      // 沒有卡片被回收
      developer.log('沒有可以自動回收的牌');
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('沒有可以自動回收的牌'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    // 確保更新狀態
    state = newState;
    developer.log('已更新遊戲狀態');

    // 檢查遊戲是否完成
    if (state.isGameCompleted) {
      saveGameRecord();
      developer.log('遊戲已完成，保存記錄');
      _showGameCompletedDialog();
    }

    // 強制通知UI更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context != null) {
        developer.log('強制刷新UI');
      }
    });
  }

  /// 保存遊戲記錄
  Future<void> saveGameRecord() async {
    if (!state.isGameCompleted || state.endTime == null) return;

    final duration = state.endTime!.difference(state.startTime);
    final record = GameRecord(
      date: DateTime.now(),
      moves: state.moveCount,
      duration: duration,
    );

    final manageHistoryUseCase =
        await ref.read(manageHistoryUseCaseProvider.future);
    await manageHistoryUseCase.saveGameRecord(record);
  }

  /// 顯示遊戲完成對話框
  void _showGameCompletedDialog() {
    if (_context == null) return;

    // 使用WidgetsBinding確保在UI更新後再顯示對話框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context == null) return;

      final duration = state.endTime!.difference(state.startTime);
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;

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
                // 使用延遲確保對話框已完全關閉後再開始新遊戲
                Future.microtask(() {
                  startNewGame();
                });
              },
              child: const Text('開始新遊戲'),
            ),
            TextButton(
              onPressed: () {
                // 只關閉對話框
                Navigator.of(dialogContext).pop();
              },
              child: const Text('關閉'),
            ),
          ],
        ),
      );
    });
  }
}
