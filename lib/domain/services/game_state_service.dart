import 'dart:developer' as developer;

import '../entities/card.dart';
import '../entities/game_state.dart';
import '../exceptions/game_exceptions.dart';
import 'card_move_validation_service.dart';

/// 遊戲狀態服務
/// 負責處理遊戲狀態相關的業務邏輯
class GameStateService {
  final CardMoveValidationService _validationService;

  GameStateService(this._validationService);

  /// 移動卡片
  /// 
  /// [state] 當前遊戲狀態
  /// [from] 起始位置
  /// [to] 目標位置
  /// 
  /// 返回更新後的遊戲狀態，如果移動無效則拋出異常
  GameState moveCard(GameState state, CardLocation from, CardLocation to) {
    // 驗證移動是否有效
    if (!_validationService.isValidMove(state, from, to)) {
      throw InvalidMoveException('無效的移動');
    }

    // 執行移動
    return _executeMove(state, from, to);
  }

  /// 檢查遊戲是否完成
  /// 
  /// [state] 遊戲狀態
  /// 
  /// 返回 true 如果遊戲已完成（所有卡片都在基礎堆中）
  bool isGameCompleted(GameState state) {
    int totalFoundationCards = 0;
    for (final foundation in state.foundation) {
      totalFoundationCards += foundation.length;
    }
    return totalFoundationCards == 52;
  }

  /// 獲取可選擇的卡片位置
  /// 
  /// [state] 遊戲狀態
  /// 
  /// 返回所有可以被選擇的卡片位置
  List<CardLocation> getSelectableCardLocations(GameState state) {
    final locations = <CardLocation>[];

    // 列中可選擇的卡片（每列的最後一張以及形成有效序列的卡片）
    for (int i = 0; i < state.columns.length; i++) {
      if (state.columns[i].isNotEmpty) {
        // 找到最長的有效序列
        final validSequenceStart = _findValidSequenceStart(state.columns[i]);
        for (int j = validSequenceStart; j < state.columns[i].length; j++) {
          locations.add(CardLocation(
            type: CardLocationType.column,
            index: i,
            subIndex: j,
          ));
        }
      }
    }

    // 自由單元中的卡片
    for (int i = 0; i < state.freeCells.length; i++) {
      if (state.freeCells[i] != null) {
        locations.add(CardLocation(
          type: CardLocationType.freeCell,
          index: i,
        ));
      }
    }

    // 基礎堆中最上面的卡片
    for (int i = 0; i < state.foundation.length; i++) {
      if (state.foundation[i].isNotEmpty) {
        locations.add(CardLocation(
          type: CardLocationType.foundation,
          index: i,
        ));
      }
    }

    return locations;
  }

  /// 獲取卡片可移動的有效位置
  /// 
  /// [state] 遊戲狀態
  /// [card] 要移動的卡片
  /// [fromLocation] 卡片當前位置
  /// 
  /// 返回所有可以移動到的有效位置
  List<CardLocation> getValidMoveLocations(
    GameState state, 
    Card card, 
    CardLocation fromLocation
  ) {
    final locations = <CardLocation>[];

    // 檢查可以移動到哪些列
    for (int i = 0; i < state.columns.length; i++) {
      final toLocation = CardLocation(type: CardLocationType.column, index: i);
      if (_validationService.isValidMove(state, fromLocation, toLocation)) {
        locations.add(toLocation);
      }
    }

    // 檢查可以移動到哪些自由單元格
    for (int i = 0; i < state.freeCells.length; i++) {
      final toLocation = CardLocation(type: CardLocationType.freeCell, index: i);
      if (_validationService.isValidMove(state, fromLocation, toLocation)) {
        locations.add(toLocation);
      }
    }

    // 檢查可以移動到哪些基礎堆
    for (int i = 0; i < state.foundation.length; i++) {
      final toLocation = CardLocation(type: CardLocationType.foundation, index: i);
      if (_validationService.isValidMove(state, fromLocation, toLocation)) {
        locations.add(toLocation);
      }
    }

    return locations;
  }

  /// 創建新遊戲狀態
  /// 
  /// 返回新的遊戲初始狀態
  GameState createNewGame() {
    return GameState.newGame();
  }

  /// 選擇卡片
  /// 
  /// [state] 當前遊戲狀態
  /// [card] 要選擇的卡片
  /// [location] 卡片位置
  /// 
  /// 返回更新後的遊戲狀態
  GameState selectCard(GameState state, Card card, CardLocation location) {
    return state.selectCard(card, location);
  }

  /// 清除選擇
  /// 
  /// [state] 當前遊戲狀態
  /// 
  /// 返回清除選擇後的遊戲狀態
  GameState clearSelection(GameState state) {
    return state.clearSelection();
  }

  /// 執行移動操作
  /// 
  /// [state] 當前遊戲狀態
  /// [from] 起始位置
  /// [to] 目標位置
  /// 
  /// 返回移動後的遊戲狀態
  GameState _executeMove(GameState state, CardLocation from, CardLocation to) {
    developer.log('執行移動：從 ${from.type}:${from.index}:${from.subIndex} 到 ${to.type}:${to.index}');

    // 獲取要移動的卡片序列
    final cardsToMove = _getCardsToMove(state, from);
    if (cardsToMove.isEmpty) {
      throw InvalidMoveException('起始位置沒有卡片');
    }

    developer.log('要移動的卡片數量：${cardsToMove.length}');
    for (int i = 0; i < cardsToMove.length; i++) {
      developer.log('卡片 $i: ${cardsToMove[i]}');
    }

    // 根據起始和目標位置類型執行移動
    var newState = _removeCardsFromSource(state, from);
    newState = _addCardsToTarget(newState, cardsToMove, to);

    // 檢查遊戲是否完成
    if (isGameCompleted(newState)) {
      newState = newState.copyWith(
        isGameCompleted: true,
        endTime: DateTime.now(),
      );
    }

    // 增加移動次數
    newState = newState.copyWith(
      moveCount: state.moveCount + 1,
      clearSelectedCard: true,
      clearSelectedCardLocation: true,
    );

    return newState;
  }

  /// 獲取要移動的卡片序列
  /// 
  /// [state] 遊戲狀態
  /// [from] 起始位置
  /// 
  /// 返回要移動的卡片列表
  List<Card> _getCardsToMove(GameState state, CardLocation from) {
    switch (from.type) {
      case CardLocationType.freeCell:
        final card = state.freeCells[from.index];
        return card != null ? [card] : [];

      case CardLocationType.foundation:
        if (state.foundation[from.index].isNotEmpty) {
          return [state.foundation[from.index].last];
        }
        return [];

      case CardLocationType.column:
        if (from.subIndex != null && from.subIndex! < state.columns[from.index].length) {
          // 返回從 subIndex 開始到列末的所有卡片（序列）
          return state.columns[from.index].sublist(from.subIndex!);
        }
        return [];

      case CardLocationType.none:
        return [];
    }
  }

  /// 從源位置移除卡片序列
  /// 
  /// [state] 遊戲狀態
  /// [from] 起始位置
  /// 
  /// 返回移除卡片後的遊戲狀態
  GameState _removeCardsFromSource(GameState state, CardLocation from) {
    switch (from.type) {
      case CardLocationType.freeCell:
        final newFreeCells = List<Card?>.from(state.freeCells);
        newFreeCells[from.index] = null;
        return state.copyWith(freeCells: newFreeCells);

      case CardLocationType.foundation:
        final newFoundation = List<List<Card>>.from(
          state.foundation.map((pile) => List<Card>.from(pile))
        );
        newFoundation[from.index].removeLast();
        return state.copyWith(foundation: newFoundation);

      case CardLocationType.column:
        final newColumns = List<List<Card>>.from(
          state.columns.map((column) => List<Card>.from(column))
        );
        // 移除從 subIndex 開始的所有卡片（支援移動序列）
        if (from.subIndex != null) {
          newColumns[from.index] = newColumns[from.index].sublist(0, from.subIndex);
        }
        return state.copyWith(columns: newColumns);

      case CardLocationType.none:
        return state;
    }
  }

  /// 將卡片序列添加到目標位置
  /// 
  /// [state] 遊戲狀態
  /// [cards] 要添加的卡片序列
  /// [to] 目標位置
  /// 
  /// 返回添加卡片後的遊戲狀態
  GameState _addCardsToTarget(GameState state, List<Card> cards, CardLocation to) {
    if (cards.isEmpty) return state;

    switch (to.type) {
      case CardLocationType.freeCell:
        // 自由單元格只能放一張卡片
        if (cards.length > 1) {
          throw InvalidMoveException('自由單元格只能放置一張卡片');
        }
        final newFreeCells = List<Card?>.from(state.freeCells);
        newFreeCells[to.index] = cards.first;
        return state.copyWith(freeCells: newFreeCells);

      case CardLocationType.foundation:
        // 基礎堆只能放一張卡片
        if (cards.length > 1) {
          throw InvalidMoveException('基礎堆只能放置一張卡片');
        }
        final newFoundation = List<List<Card>>.from(
          state.foundation.map((pile) => List<Card>.from(pile))
        );
        newFoundation[to.index].add(cards.first);
        return state.copyWith(foundation: newFoundation);

      case CardLocationType.column:
        // 列可以放置多張卡片（序列）
        final newColumns = List<List<Card>>.from(
          state.columns.map((column) => List<Card>.from(column))
        );
        newColumns[to.index].addAll(cards);
        return state.copyWith(columns: newColumns);

      case CardLocationType.none:
        return state;
    }
  }


  /// 在列中找到有效序列的起始位置
  /// 
  /// [column] 卡片列
  /// 
  /// 返回有效序列的起始索引
  int _findValidSequenceStart(List<Card> column) {
    if (column.length <= 1) return column.length - 1;

    // 從最後一張卡片開始向前檢查
    for (int i = column.length - 1; i > 0; i--) {
      final currentCard = column[i];
      final previousCard = column[i - 1];
      
      // 檢查是否形成有效序列（不同顏色且遞減）
      if (currentCard.isRed == previousCard.isRed ||
          currentCard.value != previousCard.value - 1) {
        return i;
      }
    }
    
    return 0; // 整個列都是有效序列
  }
}
