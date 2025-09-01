import 'dart:developer' as developer;

import '../entities/card.dart';
import '../entities/game_state.dart';
import 'card_move_validation_service.dart';
import 'game_state_service.dart';

/// 自動收集服務
/// 負責自動將符合條件的卡片移動到基礎堆
class AutoCollectService {
  final CardMoveValidationService _validationService;
  final GameStateService _gameStateService;

  // 花色與基礎堆的對應關係
  static const Map<CardSuit, int> _suitToFoundationMap = {
    CardSuit.heart: 0,     // 紅心 -> 基礎堆 0
    CardSuit.diamond: 1,   // 方塊 -> 基礎堆 1
    CardSuit.spade: 2,     // 黑桃 -> 基礎堆 2
    CardSuit.club: 3,      // 梅花 -> 基礎堆 3
  };

  AutoCollectService(this._validationService, this._gameStateService);

  /// 自動收集可移動的卡片到基礎堆
  /// 
  /// [state] 當前遊戲狀態
  /// 
  /// 返回自動收集後的遊戲狀態
  GameState autoCollect(GameState state) {
    developer.log('開始自動收集卡片流程...');

    var newState = state;
    bool madeMove;
    int attempts = 0;
    const maxAttempts = 52; // 防止無限循環
    int totalMovesCount = 0;

    // 記錄初始狀態
    _logFoundationState(newState, '自動收集前');

    do {
      madeMove = false;
      attempts++;
      developer.log('自動收集第 $attempts 次嘗試');

      // 按優先級收集卡片：A -> 2 -> 3 -> ... -> K
      for (final rank in CardRank.values) {
        final moveResult = _collectCardsWithRank(newState, rank);
        if (moveResult.state != newState) {
          newState = moveResult.state;
          totalMovesCount += moveResult.moveCount;
          madeMove = true;
          developer.log('成功收集點數為 ${rank.symbol} 的卡片，共移動 ${moveResult.moveCount} 張');
          break; // 找到可移動的卡片後重新開始
        }
      }
    } while (madeMove && attempts < maxAttempts);

    // 記錄最終狀態
    _logFoundationState(newState, '自動收集後');
    developer.log('自動收集完成，總共移動 $totalMovesCount 張卡片');

    // 檢查遊戲是否完成
    if (_gameStateService.isGameCompleted(newState)) {
      developer.log('通過自動收集完成遊戲！');
      newState = newState.copyWith(
        isGameCompleted: true,
        endTime: DateTime.now(),
      );
    }

    return newState;
  }

  /// 收集指定點數的卡片
  /// 
  /// [state] 當前遊戲狀態
  /// [targetRank] 目標點數
  /// 
  /// 返回收集結果（包含新狀態和移動次數）
  _AutoCollectResult _collectCardsWithRank(GameState state, CardRank targetRank) {
    var newState = state;
    int moveCount = 0;

    // 首先嘗試從列中收集
    for (int columnIndex = 0; columnIndex < state.columns.length; columnIndex++) {
      if (state.columns[columnIndex].isEmpty) continue;

      final card = state.columns[columnIndex].last;
      if (card.rank != targetRank) continue;

      final foundationIndex = _suitToFoundationMap[card.suit]!;
      if (_validationService.canPlaceInFoundation(newState, card, foundationIndex)) {
        final fromLocation = CardLocation(
          type: CardLocationType.column,
          index: columnIndex,
          subIndex: newState.columns[columnIndex].length - 1,
        );

        final toLocation = CardLocation(
          type: CardLocationType.foundation,
          index: foundationIndex,
        );

        try {
          newState = _gameStateService.moveCard(newState, fromLocation, toLocation);
          moveCount++;
          developer.log('成功從列 $columnIndex 移動 $card 到基礎堆 $foundationIndex');
        } catch (e) {
          developer.log('移動失敗：$e');
        }
      }
    }

    // 然後嘗試從自由單元格收集
    for (int freeCellIndex = 0; freeCellIndex < state.freeCells.length; freeCellIndex++) {
      if (state.freeCells[freeCellIndex] == null) continue;

      final card = state.freeCells[freeCellIndex]!;
      if (card.rank != targetRank) continue;

      final foundationIndex = _suitToFoundationMap[card.suit]!;
      if (_validationService.canPlaceInFoundation(newState, card, foundationIndex)) {
        final fromLocation = CardLocation(
          type: CardLocationType.freeCell,
          index: freeCellIndex,
        );

        final toLocation = CardLocation(
          type: CardLocationType.foundation,
          index: foundationIndex,
        );

        try {
          newState = _gameStateService.moveCard(newState, fromLocation, toLocation);
          moveCount++;
          developer.log('成功從自由單元格 $freeCellIndex 移動 $card 到基礎堆 $foundationIndex');
        } catch (e) {
          developer.log('移動失敗：$e');
        }
      }
    }

    return _AutoCollectResult(newState, moveCount);
  }

  /// 檢查是否有可自動收集的卡片
  /// 
  /// [state] 遊戲狀態
  /// 
  /// 返回 true 如果有可自動收集的卡片
  bool hasAutoCollectableCards(GameState state) {
    // 檢查列中的頂部卡片
    for (int columnIndex = 0; columnIndex < state.columns.length; columnIndex++) {
      if (state.columns[columnIndex].isEmpty) continue;

      final card = state.columns[columnIndex].last;
      final foundationIndex = _suitToFoundationMap[card.suit]!;
      if (_validationService.canPlaceInFoundation(state, card, foundationIndex)) {
        return true;
      }
    }

    // 檢查自由單元格中的卡片
    for (int freeCellIndex = 0; freeCellIndex < state.freeCells.length; freeCellIndex++) {
      if (state.freeCells[freeCellIndex] == null) continue;

      final card = state.freeCells[freeCellIndex]!;
      final foundationIndex = _suitToFoundationMap[card.suit]!;
      if (_validationService.canPlaceInFoundation(state, card, foundationIndex)) {
        return true;
      }
    }

    return false;
  }


  /// 記錄基礎堆狀態
  /// 
  /// [state] 遊戲狀態
  /// [prefix] 日誌前綴
  void _logFoundationState(GameState state, String prefix) {
    for (int i = 0; i < state.foundation.length; i++) {
      final pile = state.foundation[i];
      developer.log('$prefix：基礎堆 $i 有 ${pile.length} 張卡片');
      if (pile.isNotEmpty) {
        developer.log('頂部卡片是：${pile.last}');
      }
    }
  }
}

/// 自動收集結果
class _AutoCollectResult {
  final GameState state;
  final int moveCount;

  _AutoCollectResult(this.state, this.moveCount);
}