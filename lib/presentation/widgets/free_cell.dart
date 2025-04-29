import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/card.dart' as domain;
import '../../domain/entities/game_state.dart';
import '../providers/game_provider.dart';
import 'card_widget.dart';

/// 自由單元格組件
class FreeCellWidget extends ConsumerWidget {
  /// 單元格中的卡片，為null表示空單元格
  final domain.Card? card;

  /// 單元格索引
  final int index;

  const FreeCellWidget({
    super.key,
    required this.card,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final gameNotifier = ref.read(gameNotifierProvider.notifier);
    final isSelected =
        gameState.selectedCardLocation?.type == CardLocationType.freeCell &&
            gameState.selectedCardLocation?.index == index;

    // 創建卡片位置
    final cardLocation = card != null
        ? CardLocation(
            type: CardLocationType.freeCell,
            index: index,
          )
        : null;

    // 使用 DragTarget 包裝整個自由單元格
    return DragTarget<DraggableCardData>(
      onWillAcceptWithDetails: (details) {
        // 只接受空的自由單元格
        return card == null;
      },
      onAcceptWithDetails: (details) {
        // 移動卡片到此自由單元格
        final toLocation = CardLocation(
          type: CardLocationType.freeCell,
          index: index,
        );
        gameNotifier.tryMoveCard(details.data.location, toLocation);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            if (card != null) {
              // 如果單元格有卡片
              if (gameState.selectedCard == null) {
                // 如果當前沒有選中卡片，選擇此卡片
                final location = CardLocation(
                  type: CardLocationType.freeCell,
                  index: index,
                );

                gameNotifier.selectCard(card!, location);
              } else if (isSelected) {
                // 如果點擊了已選中的卡片，取消選擇
                gameNotifier.clearSelection();
              } else {
                // 如果已選擇了其他卡片，直接選擇這張新的卡片
                final location = CardLocation(
                  type: CardLocationType.freeCell,
                  index: index,
                );

                gameNotifier.selectCard(card!, location);
              }
            } else if (gameState.selectedCard != null &&
                gameState.selectedCardLocation != null) {
              // 如果單元格為空，且已選擇了卡片，嘗試移動到此單元格
              final toLocation = CardLocation(
                type: CardLocationType.freeCell,
                index: index,
              );

              gameNotifier.tryMoveCard(
                  gameState.selectedCardLocation!, toLocation);
            }
          },
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(4),
            color: candidateData.isNotEmpty
                ? Colors.greenAccent.withOpacity(0.3) // 拖動高亮
                : isSelected
                    ? Colors.blueAccent.withOpacity(0.3)
                    : Colors.grey.shade200,
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: card != null
                  ? CardWidgetSimple(
                      card: card!,
                      isSelected: isSelected,
                      size: 60,
                      isDraggable: true, // 啟用拖動
                      location: cardLocation,
                    )
                  : const Text('自由格'),
            ),
          ),
        );
      },
    );
  }
}
