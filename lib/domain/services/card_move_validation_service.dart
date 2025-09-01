import '../entities/card.dart';
import '../entities/game_state.dart';

/// 卡片移動驗證服務
/// 負責驗證各種卡片移動操作的有效性
class CardMoveValidationService {
  /// 檢查移動是否有效
  /// 
  /// [state] 當前遊戲狀態
  /// [from] 起始位置
  /// [to] 目標位置
  /// 
  /// 返回 true 如果移動有效，否則返回 false
  bool isValidMove(GameState state, CardLocation from, CardLocation to) {
    // 獲取要移動的卡片序列
    final cardsToMove = _getCardsToMove(state, from);
    if (cardsToMove.isEmpty) return false;

    // 如果只有一張卡片，使用原有邏輯
    if (cardsToMove.length == 1) {
      return _canPlaceCardAt(state, cardsToMove.first, to, from);
    }

    // 如果是多張卡片（序列），需要特殊處理
    return _canMoveCardSequence(state, cardsToMove, from, to);
  }

  /// 檢查是否可以移動整個卡片序列
  /// 
  /// [state] 當前遊戲狀態
  /// [cards] 要移動的卡片序列
  /// [from] 起始位置
  /// [to] 目標位置
  /// 
  /// 返回 true 如果可以移動整個序列，否則返回 false
  bool canMoveCardSequence(
    GameState state, 
    List<Card> cards, 
    CardLocation from, 
    CardLocation to
  ) {
    if (cards.isEmpty) return false;

    // 檢查序列是否有效（不同顏色且遞減）
    if (!_isValidCardSequence(cards)) return false;

    // 只能移動到列
    if (to.type != CardLocationType.column) return false;

    // 檢查目標列是否可以放置第一張卡片
    return _canPlaceCardAt(state, cards.first, to, from);
  }

  /// 檢查卡片是否可以放到自由單元格
  /// 
  /// [state] 當前遊戲狀態
  /// [cellIndex] 自由單元格索引
  /// 
  /// 返回 true 如果自由單元格為空，否則返回 false
  bool canPlaceInFreeCell(GameState state, int cellIndex) {
    if (cellIndex < 0 || cellIndex >= state.freeCells.length) return false;
    return state.freeCells[cellIndex] == null;
  }

  /// 檢查卡片是否可以放到基礎堆
  /// 
  /// [state] 當前遊戲狀態
  /// [card] 要放置的卡片
  /// [foundationIndex] 基礎堆索引
  /// 
  /// 返回 true 如果卡片可以放到基礎堆，否則返回 false
  bool canPlaceInFoundation(GameState state, Card card, int foundationIndex) {
    if (foundationIndex < 0 || foundationIndex >= state.foundation.length) {
      return false;
    }
    return card.canPlaceInFoundation(state.foundation[foundationIndex], foundationIndex);
  }

  /// 檢查卡片是否可以放到列
  /// 
  /// [state] 當前遊戲狀態
  /// [card] 要放置的卡片
  /// [columnIndex] 列索引
  /// 
  /// 返回 true 如果卡片可以放到列，否則返回 false
  bool canPlaceInColumn(GameState state, Card card, int columnIndex) {
    if (columnIndex < 0 || columnIndex >= state.columns.length) return false;

    final column = state.columns[columnIndex];
    
    // 空列可以放置任何卡片
    if (column.isEmpty) return true;

    // 非空列需要檢查頂部卡片是否可以放置選中的卡片
    return card.canPlaceOnCard(column.last);
  }

  /// 檢查卡片序列是否有效（不同顏色且遞減）
  /// 
  /// [cards] 卡片序列
  /// 
  /// 返回 true 如果序列有效，否則返回 false
  bool _isValidCardSequence(List<Card> cards) {
    if (cards.length <= 1) return true;

    for (int i = 0; i < cards.length - 1; i++) {
      final currentCard = cards[i];
      final nextCard = cards[i + 1];
      
      // 檢查顏色是否不同且點數遞減
      if (currentCard.isRed == nextCard.isRed || 
          currentCard.value != nextCard.value + 1) {
        return false;
      }
    }
    return true;
  }


  /// 檢查卡片是否可以放置到指定位置
  /// 
  /// [state] 遊戲狀態
  /// [card] 要放置的卡片
  /// [to] 目標位置
  /// [from] 起始位置（用於避免自己放置到自己）
  /// 
  /// 返回 true 如果可以放置，否則返回 false
  bool _canPlaceCardAt(GameState state, Card card, CardLocation to, CardLocation from) {
    // 不能移動到自己的位置
    if (from == to) return false;

    switch (to.type) {
      case CardLocationType.column:
        // 如果移動到相同的列，需要特殊處理
        if (from.type == CardLocationType.column && from.index == to.index) {
          return false;
        }
        return canPlaceInColumn(state, card, to.index);
      case CardLocationType.freeCell:
        return canPlaceInFreeCell(state, to.index);
      case CardLocationType.foundation:
        return canPlaceInFoundation(state, card, to.index);
      case CardLocationType.none:
        return false;
    }
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

  /// 檢查是否可以移動卡片序列（內部方法）
  /// 
  /// [state] 當前遊戲狀態
  /// [cards] 要移動的卡片序列
  /// [from] 起始位置
  /// [to] 目標位置
  /// 
  /// 返回 true 如果可以移動整個序列，否則返回 false
  bool _canMoveCardSequence(
    GameState state, 
    List<Card> cards, 
    CardLocation from, 
    CardLocation to
  ) {
    if (cards.isEmpty) return false;

    // 檢查序列是否有效（不同顏色且遞減）
    if (!_isValidCardSequence(cards)) return false;

    // 多張卡片序列只能移動到列
    if (to.type != CardLocationType.column) return false;

    // 不能移動到相同的列
    if (from.type == CardLocationType.column && from.index == to.index) {
      return false;
    }

    // 檢查目標列是否可以放置第一張卡片
    return canPlaceInColumn(state, cards.first, to.index);
  }
}