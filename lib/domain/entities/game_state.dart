// 遊戲狀態實體類定義
// 表示FreeCell遊戲的完整狀態

import 'dart:developer' as developer;

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

  /// 移動卡片
  /// [from] 卡片的起始位置
  /// [to] 卡片的目标位置
  GameState moveCard(CardLocation from, CardLocation to) {
    // 從源位置獲取卡片
    domain.Card? cardToMove;
    List<domain.Card>? cardsToMove; // 對於列，可能需要移動多張卡片

    // 如果使用 -1 作為標記，表示使用選中的卡片
    if (from.index == -1 &&
        selectedCard != null &&
        selectedCardLocation != null) {
      from = selectedCardLocation!;
    }

    switch (from.type) {
      case CardLocationType.freeCell:
        if (from.index < 0 || from.index >= freeCells.length) {
          developer.log('moveCard 失敗：自由單元格索引無效');
          return this;
        }
        cardToMove = freeCells[from.index];
        if (cardToMove == null) {
          developer.log('moveCard 失敗：選擇的自由單元格沒有卡片');
          return this;
        }
        break;
      case CardLocationType.foundation:
        if (from.index < 0 || from.index >= foundation.length) {
          developer.log('moveCard 失敗：基礎堆索引無效');
          return this;
        }
        if (foundation[from.index].isEmpty) {
          developer.log('moveCard 失敗：選擇的基礎堆沒有卡片');
          return this;
        }
        cardToMove = foundation[from.index].last;
        break;
      case CardLocationType.column:
        if (from.index < 0 || from.index >= columns.length) {
          developer.log('moveCard 失敗：列索引無效');
          return this;
        }
        if (from.subIndex == null ||
            from.subIndex! < 0 ||
            from.subIndex! >= columns[from.index].length) {
          developer.log('moveCard 失敗：列子索引無效');
          return this;
        }
        // 從列的子索引開始獲取所有卡片
        cardsToMove = columns[from.index].sublist(from.subIndex!);
        cardToMove = columns[from.index][from.subIndex!];
        break;
      case CardLocationType.none:
        developer.log('moveCard 失敗：卡片位置類型為 none');
        return this;
    }

    // 根據目標位置執行移動
    switch (to.type) {
      case CardLocationType.freeCell:
        return _moveToFreeCell(cardToMove, from, to.index);
      case CardLocationType.foundation:
        return _moveToFoundation(cardToMove, from, to.index);
      case CardLocationType.column:
        return _moveToColumn(
            cardToMove, cardsToMove ?? [cardToMove], from, to.index);
      case CardLocationType.none:
        developer.log('moveCard 失敗：目標位置類型為 none');
        return this;
    }
  }

  /// 移動卡片到自由單元格
  GameState _moveToFreeCell(
      domain.Card card, CardLocation from, int toCellIndex) {
    // 檢查目標自由單元格是否為空
    if (freeCells[toCellIndex] != null) {
      developer.log('_moveToFreeCell 失敗：目標自由單元格已有卡片');
      return this;
    }

    // 創建新狀態
    var newState = _removeCardFromSource(card, from);

    // 更新自由單元格
    var newFreeCells = List<domain.Card?>.from(newState.freeCells);
    newFreeCells[toCellIndex] = card;

    return newState.copyWith(
      freeCells: newFreeCells,
      selectedCard: null,
      selectedCardLocation: null,
      moveCount: moveCount + 1,
    );
  }

  /// 移動卡片到基礎堆
  GameState _moveToFoundation(
      domain.Card card, CardLocation from, int toFoundIndex) {
    developer.log(
        '嘗試將卡片 $card 從位置 ${from.type}:${from.index}:${from.subIndex} 移動到基礎堆 $toFoundIndex');

    // 檢查是否可以放入基礎堆
    if (!card.canPlaceInFoundation(foundation[toFoundIndex], toFoundIndex)) {
      developer.log('_moveToFoundation 失敗：卡片無法放入基礎堆');
      return this;
    }

    // 創建新狀態
    developer.log('從源位置移除卡片 $card');
    var newState = _removeCardFromSource(card, from);

    // 檢查是否正確移除
    if (from.type == CardLocationType.column && from.subIndex != null) {
      if (from.subIndex! < columns[from.index].length &&
          columns[from.index][from.subIndex!] == card &&
          (newState.columns[from.index].length ==
              columns[from.index].length -
                  (columns[from.index].length - from.subIndex!))) {
        developer.log('卡片移除成功');
      } else {
        developer.log('警告：卡片可能未正確從列中移除');
      }
    } else if (from.type == CardLocationType.freeCell) {
      if (freeCells[from.index] == card &&
          newState.freeCells[from.index] == null) {
        developer.log('卡片移除成功');
      } else {
        developer.log('警告：卡片可能未正確從自由單元格移除');
      }
    }

    // 更新基礎堆
    var newFoundation = List<List<domain.Card>>.from(newState.foundation);
    newFoundation[toFoundIndex] = [...newState.foundation[toFoundIndex], card];

    developer.log(
        '將卡片 $card 添加到基礎堆 $toFoundIndex，現在有 ${newFoundation[toFoundIndex].length} 張卡片');

    return newState.copyWith(
      foundation: newFoundation,
      selectedCard: null,
      selectedCardLocation: null,
      moveCount: moveCount + 1,
    );
  }

  /// 移動卡片到遊戲列
  GameState _moveToColumn(domain.Card card, List<domain.Card> cards,
      CardLocation from, int toColIndex) {
    // 檢查目標列是否為空，或者頂部卡片是否可以疊放
    bool canPlace = columns[toColIndex].isEmpty ||
        card.canPlaceOnCard(columns[toColIndex].last);

    if (!canPlace) {
      developer.log('_moveToColumn 失敗：卡片無法放入列中');
      return this;
    }

    // 創建新狀態
    var newState = _removeCardFromSource(card, from);

    // 更新目標列
    var newColumns = List<List<domain.Card>>.from(newState.columns);
    newColumns[toColIndex] = [...newState.columns[toColIndex], ...cards];

    return newState.copyWith(
      columns: newColumns,
      selectedCard: null,
      selectedCardLocation: null,
      moveCount: moveCount + 1,
    );
  }

  /// 從源位置移除卡片
  GameState _removeCardFromSource(domain.Card card, CardLocation from) {
    var newFreeCells = List<domain.Card?>.from(freeCells);
    var newFoundation = List<List<domain.Card>>.from(foundation);
    var newColumns = List<List<domain.Card>>.from(columns);

    switch (from.type) {
      case CardLocationType.freeCell:
        newFreeCells[from.index] = null;
        break;
      case CardLocationType.foundation:
        newFoundation[from.index] = foundation[from.index]
            .sublist(0, foundation[from.index].length - 1);
        break;
      case CardLocationType.column:
        newColumns[from.index] = columns[from.index].sublist(0, from.subIndex);
        break;
      case CardLocationType.none:
        // 不需要移除
        break;
    }

    return copyWith(
      freeCells: newFreeCells,
      foundation: newFoundation,
      columns: newColumns,
    );
  }

  /// 嘗試自動將卡片移到基礎堆
  GameState tryAutoMoveToFoundation() {
    var newState = this;
    bool madeMove;

    do {
      madeMove = false;

      // 檢查列中的頂部卡片
      for (int colIndex = 0; colIndex < newState.columns.length; colIndex++) {
        if (newState.columns[colIndex].isEmpty) continue;

        var card = newState.columns[colIndex].last;

        // 嘗試將卡片放入適當的基礎堆
        for (int foundIndex = 0;
            foundIndex < newState.foundation.length;
            foundIndex++) {
          if (card.canPlaceInFoundation(
              newState.foundation[foundIndex], foundIndex)) {
            // 直接移動卡片，不需要先選擇
            final fromLocation = CardLocation(
              type: CardLocationType.column,
              index: colIndex,
              subIndex: newState.columns[colIndex].length - 1,
            );

            final toLocation = CardLocation(
              type: CardLocationType.foundation,
              index: foundIndex,
            );

            // 直接使用 moveCard 方法
            newState = newState.moveCard(fromLocation, toLocation);
            developer.log('自動移動：從列 $colIndex 移動卡片 $card 到基礎堆 $foundIndex');

            madeMove = true;
            break;
          }
        }

        if (madeMove) break;
      }

      // 如果列中沒有可移動的卡片，檢查自由單元
      if (!madeMove) {
        for (int cellIndex = 0;
            cellIndex < newState.freeCells.length;
            cellIndex++) {
          if (newState.freeCells[cellIndex] == null) continue;

          var card = newState.freeCells[cellIndex]!;

          // 嘗試將卡片放入適當的基礎堆
          for (int foundIndex = 0;
              foundIndex < newState.foundation.length;
              foundIndex++) {
            if (card.canPlaceInFoundation(
                newState.foundation[foundIndex], foundIndex)) {
              // 直接移動卡片，不需要先選擇
              final fromLocation = CardLocation(
                type: CardLocationType.freeCell,
                index: cellIndex,
              );

              final toLocation = CardLocation(
                type: CardLocationType.foundation,
                index: foundIndex,
              );

              // 直接使用 moveCard 方法
              newState = newState.moveCard(fromLocation, toLocation);
              developer
                  .log('自動移動：從自由單元格 $cellIndex 移動卡片 $card 到基礎堆 $foundIndex');

              madeMove = true;
              break;
            }
          }

          if (madeMove) break;
        }
      }
    } while (madeMove);

    return newState;
  }

  /// 獲取可選擇的卡片位置
  List<CardLocation> getSelectableCardLocations() {
    final List<CardLocation> locations = [];

    // 列中可選擇的卡片（每列的最後一張）
    for (int i = 0; i < columns.length; i++) {
      if (columns[i].isNotEmpty) {
        locations.add(CardLocation(
          type: CardLocationType.column,
          index: i,
          subIndex: columns[i].length - 1,
        ));
      }
    }

    // 自由單元中的卡片
    for (int i = 0; i < freeCells.length; i++) {
      if (freeCells[i] != null) {
        locations.add(CardLocation(
          type: CardLocationType.freeCell,
          index: i,
        ));
      }
    }

    // 基礎堆中最上面的卡片（通常不會從基礎堆中移出，但允許選擇）
    for (int i = 0; i < foundation.length; i++) {
      if (foundation[i].isNotEmpty) {
        locations.add(CardLocation(
          type: CardLocationType.foundation,
          index: i,
        ));
      }
    }

    return locations;
  }

  /// 獲取卡片可放置的位置
  List<CardLocation> getValidMoveLocations(
      domain.Card card, CardLocation fromLocation) {
    final List<CardLocation> locations = [];

    // 檢查可以放置到哪些列
    for (int i = 0; i < columns.length; i++) {
      // 跳過源列
      if (fromLocation.type == CardLocationType.column &&
          fromLocation.index == i) {
        continue;
      }

      if (columns[i].isEmpty || card.canPlaceOnCard(columns[i].last)) {
        locations.add(CardLocation(
          type: CardLocationType.column,
          index: i,
        ));
      }
    }

    // 檢查可以放置到哪些自由單元
    for (int i = 0; i < freeCells.length; i++) {
      if (freeCells[i] == null) {
        locations.add(CardLocation(
          type: CardLocationType.freeCell,
          index: i,
        ));
      }
    }

    // 檢查可以放置到哪些基礎堆
    for (int i = 0; i < foundation.length; i++) {
      if (card.canPlaceInFoundation(foundation[i], i)) {
        locations.add(CardLocation(
          type: CardLocationType.foundation,
          index: i,
        ));
      }
    }

    return locations;
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
