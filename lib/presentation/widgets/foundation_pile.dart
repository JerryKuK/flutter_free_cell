import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/card.dart' as domain;
import '../../domain/entities/game_state.dart';
import '../providers/game_provider.dart';
import 'card_widget.dart';

/// 基礎堆組件
class FoundationPileWidget extends ConsumerWidget {
  /// 基礎堆中的卡片
  final List<domain.Card> pile;

  /// 基礎堆索引
  final int index;

  const FoundationPileWidget({
    super.key,
    required this.pile,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    developer.log('渲染基礎堆 $index，包含 ${pile.length} 張卡片');
    if (pile.isNotEmpty) {
      developer.log('頂部卡片是：${pile.last}');
    }

    final gameState = ref.watch(gameNotifierProvider);
    final isSelected =
        gameState.selectedCardLocation?.type == CardLocationType.foundation &&
            gameState.selectedCardLocation?.index == index;

    // 確認 gameState 中的基礎堆與傳入的 pile 是否一致
    final statePile = gameState.foundation[index];
    developer.log('從 gameState 獲取的基礎堆 $index 有 ${statePile.length} 張卡片');
    if (statePile.length != pile.length) {
      developer.log('警告：gameState 與 props 中的基礎堆數據不一致！');
    }

    return GestureDetector(
      onTap: () {
        final gameNotifier = ref.read(gameNotifierProvider.notifier);

        if (pile.isNotEmpty) {
          // 如果基礎堆不為空
          if (isSelected) {
            // 如果點擊的是已選中的卡片，取消選擇
            gameNotifier.clearSelection();
          } else if (gameState.selectedCard == null) {
            // 如果沒有選擇卡片，選擇基礎堆頂部卡片
            final location = CardLocation(
              type: CardLocationType.foundation,
              index: index,
            );

            developer.log('選擇基礎堆 $index 頂部卡片：${pile.last}');
            gameNotifier.selectCard(pile.last, location);
          } else {
            // 如果已選擇卡片，且點擊有卡片的基礎堆，嘗試選擇基礎堆頂部卡片
            final location = CardLocation(
              type: CardLocationType.foundation,
              index: index,
            );

            developer.log('選擇基礎堆 $index 頂部卡片：${pile.last}');
            gameNotifier.selectCard(pile.last, location);
          }
        } else if (gameState.selectedCard != null &&
            gameState.selectedCardLocation != null) {
          // 如果基礎堆為空且已選擇卡片，嘗試移動到基礎堆
          final toLocation = CardLocation(
            type: CardLocationType.foundation,
            index: index,
          );

          developer.log('嘗試移動卡片到基礎堆 $index');
          gameNotifier.tryMoveCard(gameState.selectedCardLocation!, toLocation);
        }
      },
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(4),
        color: isSelected
            ? Colors.blueAccent.withOpacity(0.3)
            : Colors.grey.shade200,
        child: Container(
          height: 70,
          alignment: Alignment.center,
          child: pile.isNotEmpty
              ? CardWidget(
                  card: pile.last,
                  isSelected: isSelected,
                  size: 60,
                )
              : Text(
                  _getSuitSymbol(index),
                  style: TextStyle(
                    fontSize: 24,
                    color: _isRedSuit(index) ? Colors.red : Colors.black,
                  ),
                ),
        ),
      ),
    );
  }

  /// 獲取花色符號
  String _getSuitSymbol(int index) {
    switch (index) {
      case 0:
        return '♥'; // 紅心
      case 1:
        return '♦'; // 方塊
      case 2:
        return '♠'; // 黑桃
      case 3:
        return '♣'; // 梅花
      default:
        return '';
    }
  }

  /// 判斷是否為紅色花色
  bool _isRedSuit(int index) {
    return index == 0 || index == 1; // 紅心和方塊是紅色
  }
}
