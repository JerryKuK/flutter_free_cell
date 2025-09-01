// 卡片實體類定義
// 代表一張撲克牌的基本信息，屬於領域層的核心概念

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// 卡片花色枚舉
enum CardSuit {
  heart('♥'),
  diamond('♦'),
  spade('♠'),
  club('♣');

  final String symbol;
  const CardSuit(this.symbol);

  bool get isRed => this == CardSuit.heart || this == CardSuit.diamond;
}

/// 卡片點數枚舉
enum CardRank {
  ace('A', 1),
  two('2', 2),
  three('3', 3),
  four('4', 4),
  five('5', 5),
  six('6', 6),
  seven('7', 7),
  eight('8', 8),
  nine('9', 9),
  ten('10', 10),
  jack('J', 11),
  queen('Q', 12),
  king('K', 13);

  final String symbol;
  final int value;
  const CardRank(this.symbol, this.value);
}


/// 卡片實體
@immutable
class Card {
  final CardSuit suit;
  final CardRank rank;

  const Card({
    required this.suit,
    required this.rank,
  });

  /// 判斷是否是紅色牌
  bool get isRed => suit.isRed;

  /// 獲取卡片點數值
  int get value => rank.value;

  /// 判斷是否可以放在另一張牌上（不同顏色且點數連續遞減）
  bool canPlaceOnCard(Card otherCard) {
    return otherCard.value == value + 1 && otherCard.isRed != isRed;
  }

  /// 判斷是否可以放入基礎堆
  bool canPlaceInFoundation(List<Card> foundation, [int foundationIndex = -1]) {
    // 添加日誌，以便調試
    developer.log(
        '嘗試將卡片 $this 放入基礎堆 $foundationIndex，基礎堆為 ${foundation.isEmpty ? "空" : "包含 ${foundation.length} 張卡片"}');

    if (foundation.isEmpty) {
      // 確保A只能放入對應花色的基礎堆
      final isAce = rank == CardRank.ace;

      // 如果沒有提供索引，只檢查是否為A
      if (foundationIndex == -1) {
        developer.log('基礎堆為空，卡片是A? $isAce，未提供基礎堆索引');
        return isAce;
      }

      // 根據基礎堆索引判斷期望的花色
      CardSuit? expectedSuit;
      switch (foundationIndex) {
        case 0:
          expectedSuit = CardSuit.heart; // 紅心
          break;
        case 1:
          expectedSuit = CardSuit.diamond; // 方塊
          break;
        case 2:
          expectedSuit = CardSuit.spade; // 黑桃
          break;
        case 3:
          expectedSuit = CardSuit.club; // 梅花
          break;
      }

      final suitMatch = suit == expectedSuit;
      developer.log(
          '基礎堆為空，卡片是A? $isAce，花色匹配? $suitMatch (期望花色: ${expectedSuit?.symbol})');
      return isAce && suitMatch;
    }

    final topCard = foundation.last;
    final suitMatch = topCard.suit == suit;
    final valueMatch = topCard.value == value - 1;
    developer.log('基礎堆頂部卡片為 $topCard，花色匹配? $suitMatch，點數連續? $valueMatch');

    return suitMatch && valueMatch;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          rank == other.rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;

  @override
  String toString() => '${suit.symbol}${rank.symbol}';
}
