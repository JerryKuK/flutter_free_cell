// 遊戲狀態實體類定義
// 表示FreeCell遊戲的完整狀態


import 'package:flutter/foundation.dart';

import 'card.dart' as domain;

/// 遊戲狀態實體
@immutable
class GameState {
  /// 列（tableau）數組，每個列包含一組卡片
  final List<List<domain.Card>> columns;

  /// 自由單元（freecell）數組，每個單元可以存放一張卡片
  final List<domain.Card?> freeCells;

  /// 基礎堆（foundation）數組，按花色存放卡片
  final List<List<domain.Card>> foundation;

  /// 當前選中的卡片
  final domain.Card? selectedCard;

  /// 當前選中的卡片來源位置
  final CardLocation? selectedCardLocation;

  /// 遊戲是否已完成
  final bool isGameCompleted;

  /// 遊戲開始時間
  final DateTime startTime;

  /// 遊戲結束時間（如果已完成）
  final DateTime? endTime;

  /// 移動次數計數
  final int moveCount;

  const GameState({
    required this.columns,
    required this.freeCells,
    required this.foundation,
    this.selectedCard,
    this.selectedCardLocation,
    this.isGameCompleted = false,
    required this.startTime,
    this.endTime,
    this.moveCount = 0,
  });

  /// 創建新遊戲的初始狀態
  factory GameState.newGame() {
    // 創建一副完整的牌
    final allCards = <domain.Card>[];
    for (final suit in domain.CardSuit.values) {
      for (final rank in domain.CardRank.values) {
        allCards.add(domain.Card(suit: suit, rank: rank));
      }
    }

    // 洗牌
    allCards.shuffle();

    // 分配到8列
    final columns = List<List<domain.Card>>.generate(8, (_) => []);

    // 將牌分配到8列中（每列6-7張牌）
    for (int i = 0; i < allCards.length; i++) {
      columns[i % 8].add(allCards[i]);
    }

    // 創建空的自由單元
    final freeCells = List<domain.Card?>.filled(4, null);

    // 創建空的基礎堆
    final foundation = List<List<domain.Card>>.generate(4, (_) => []);

    return GameState(
      columns: columns,
      freeCells: freeCells,
      foundation: foundation,
      startTime: DateTime.now(),
    );
  }

  /// 創建遊戲狀態的副本
  GameState copyWith({
    List<List<domain.Card>>? columns,
    List<domain.Card?>? freeCells,
    List<List<domain.Card>>? foundation,
    domain.Card? selectedCard,
    bool clearSelectedCard = false,
    CardLocation? selectedCardLocation,
    bool clearSelectedCardLocation = false,
    bool? isGameCompleted,
    DateTime? startTime,
    DateTime? endTime,
    int? moveCount,
  }) {
    return GameState(
      columns: columns ??
          List.from(
              this.columns.map((column) => List<domain.Card>.from(column))),
      freeCells: freeCells ?? List<domain.Card?>.from(this.freeCells),
      foundation: foundation ??
          List.from(
              this.foundation.map((pile) => List<domain.Card>.from(pile))),
      selectedCard:
          clearSelectedCard ? null : (selectedCard ?? this.selectedCard),
      selectedCardLocation: clearSelectedCardLocation
          ? null
          : (selectedCardLocation ?? this.selectedCardLocation),
      isGameCompleted: isGameCompleted ?? this.isGameCompleted,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      moveCount: moveCount ?? this.moveCount,
    );
  }

  /// 檢查遊戲是否已完成
  bool checkGameCompleted() {
    // 當所有52張牌都在基礎堆中時，遊戲完成
    int totalFoundationCards =
        foundation.fold(0, (sum, pile) => sum + pile.length);
    return totalFoundationCards == 52;
  }

  /// 選擇卡片
  GameState selectCard(domain.Card card, CardLocation location) {
    return copyWith(
      selectedCard: card,
      selectedCardLocation: location,
    );
  }

  /// 取消選擇卡片
  GameState clearSelection() {
    return copyWith(
      clearSelectedCard: true,
      clearSelectedCardLocation: true,
    );
  }



  /// 獲取某個位置的卡片
  domain.Card? getCardAt(CardLocation location) {
    switch (location.type) {
      case CardLocationType.column:
        if (location.subIndex != null &&
            location.index < columns.length &&
            location.subIndex! < columns[location.index].length) {
          return columns[location.index][location.subIndex!];
        }
        return null;
      case CardLocationType.freeCell:
        if (location.index < freeCells.length) {
          return freeCells[location.index];
        }
        return null;
      case CardLocationType.foundation:
        if (location.index < foundation.length &&
            foundation[location.index].isNotEmpty) {
          return foundation[location.index].last;
        }
        return null;
      case CardLocationType.none:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          runtimeType == other.runtimeType &&
          listEquals(columns, other.columns) &&
          listEquals(freeCells, other.freeCells) &&
          listEquals(foundation, other.foundation) &&
          selectedCard == other.selectedCard &&
          selectedCardLocation == other.selectedCardLocation &&
          isGameCompleted == other.isGameCompleted &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          moveCount == other.moveCount;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(columns),
        Object.hashAll(freeCells),
        Object.hashAll(foundation),
        selectedCard,
        selectedCardLocation,
        isGameCompleted,
        startTime,
        endTime,
        moveCount,
      );
}

/// 卡片位置枚舉
enum CardLocationType { column, freeCell, foundation, none }

/// 卡片位置類
@immutable
class CardLocation {
  final CardLocationType type;
  final int index;
  final int? subIndex; // 用於列中的卡片位置

  const CardLocation({
    required this.type,
    required this.index,
    this.subIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardLocation &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          index == other.index &&
          subIndex == other.subIndex;

  @override
  int get hashCode => Object.hash(type, index, subIndex);

  @override
  String toString() =>
      'CardLocation(type: $type, index: $index, subIndex: $subIndex)';
}
