import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/card.dart' as domain;
import '../../domain/entities/game_state.dart';
import '../providers/game_provider.dart';
import 'card_widget.dart';

/// 遊戲列組件
class GameColumnWidget extends ConsumerStatefulWidget {
  /// 列中的卡片
  final List<domain.Card> column;

  /// 列索引
  final int columnIndex;

  const GameColumnWidget({
    super.key,
    required this.column,
    required this.columnIndex,
  });

  @override
  ConsumerState<GameColumnWidget> createState() => _GameColumnWidgetState();
}

class _GameColumnWidgetState extends ConsumerState<GameColumnWidget> {
  // 當前拖動的牌索引，用於確定哪些牌需要透明顯示
  int? draggingCardIndex;

  @override
  void didUpdateWidget(GameColumnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當列中的卡片發生變化時（如開始新遊戲），重置拖動狀態
    if (oldWidget.column.length != widget.column.length ||
        (oldWidget.column.isNotEmpty &&
            widget.column.isNotEmpty &&
            oldWidget.column[0] != widget.column[0])) {
      setState(() {
        draggingCardIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);
    final gameNotifier = ref.read(gameNotifierProvider.notifier);
    final column = widget.column;
    final columnIndex = widget.columnIndex;

    return Container(
      width: MediaQuery.of(context).size.width / 8.5,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Column(
        children: [
          // 列頂部的空白區域（可放置卡片）- 使用 DragTarget
          DragTarget<DraggableCardData>(
            onWillAcceptWithDetails: (details) {
              // 如果列為空，則接受任何卡片
              if (column.isEmpty) return true;

              // 否則，檢查卡片是否可以放置在列頂部
              return details.data.card.canPlaceOnCard(column.last);
            },
            onAcceptWithDetails: (details) {
              // 重置拖動狀態
              setState(() {
                draggingCardIndex = null;
              });

              // 嘗試移動卡片
              final toLocation = CardLocation(
                type: CardLocationType.column,
                index: columnIndex,
              );

              gameNotifier.tryMoveCard(details.data.location, toLocation);
            },
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTap: () {
                  if (column.isEmpty &&
                      gameState.selectedCard != null &&
                      gameState.selectedCardLocation != null) {
                    // 如果列為空且已選擇卡片，嘗試移動到此列
                    final toLocation = CardLocation(
                      type: CardLocationType.column,
                      index: columnIndex,
                    );

                    gameNotifier.tryMoveCard(
                      gameState.selectedCardLocation!,
                      toLocation,
                    );
                  }
                },
                child: Container(
                  height: 25,
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? Colors.greenAccent.withOpacity(0.3) // 拖動時高亮顯示
                        : column.isEmpty
                            ? Colors.blueAccent.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.black12,
                      width: column.isEmpty ? 1 : 0,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 5),
          // 列中的牌 - 堆疊顯示
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (column.isEmpty) {
                  return Container(); // 如果列為空，則顯示空容器
                }

                // 計算牌的堆疊偏移量，保證所有牌都在可見範圍內
                double maxHeight = constraints.maxHeight;
                int cardCount = column.length;
                double availableHeight = maxHeight - 60; // 減去一張牌的高度，確保最後一張牌完全可見
                double offset =
                    cardCount <= 1 ? 0 : availableHeight / (cardCount - 1);

                // 限制偏移量在合理範圍內
                offset = offset.clamp(15.0, 35.0);

                return Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: List.generate(cardCount, (cardIndex) {
                    // 創建每張牌的堆疊效果
                    domain.Card currentCard = column[cardIndex];

                    // 檢查當前牌是否可選擇（頂部牌或形成有效序列的一部分）
                    bool isSelectable = _isCardSelectable(cardIndex);

                    // 檢查當前牌是否是選中的牌組的一部分
                    bool isSelected = _isCardSelected(
                        cardIndex, ref.read(gameNotifierProvider));

                    // 檢查當前牌是否應該透明顯示（正在被拖動）
                    bool shouldBeTransparent = draggingCardIndex != null &&
                        cardIndex >= draggingCardIndex!;

                    // 創建卡片位置對象
                    final location = CardLocation(
                      type: CardLocationType.column,
                      index: columnIndex,
                      subIndex: cardIndex,
                    );

                    return Positioned(
                      top: cardIndex * offset, // 動態計算偏移量
                      child: GestureDetector(
                        // 允許點擊任何牌
                        onTap: () => _handleCardTap(cardIndex, ref),
                        child: cardIndex == column.length - 1
                            ? DragTarget<DraggableCardData>(
                                onWillAcceptWithDetails: (details) {
                                  return details.data.card
                                      .canPlaceOnCard(currentCard);
                                },
                                onAcceptWithDetails: (details) {
                                  // 重置拖動狀態
                                  setState(() {
                                    draggingCardIndex = null;
                                  });

                                  final toLocation = CardLocation(
                                    type: CardLocationType.column,
                                    index: columnIndex,
                                  );
                                  gameNotifier.tryMoveCard(
                                      details.data.location, toLocation);
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.blue, width: 2)
                                          : candidateData.isNotEmpty
                                              ? Border.all(
                                                  color: Colors.green, width: 2)
                                              : null,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: shouldBeTransparent
                                        ? Opacity(
                                            opacity: 0.3,
                                            child: CardWidget(
                                              card: currentCard,
                                              isSelectable: false,
                                              isSelected: false,
                                              size: 40,
                                            ),
                                          )
                                        : CardWidget(
                                            card: currentCard,
                                            isSelectable: isSelectable,
                                            isSelected: isSelected,
                                            size: 40,
                                            location: location,
                                            subIndex: cardIndex,
                                            isDraggable:
                                                isSelectable, // 只有可選擇的牌才可拖動
                                          ),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: isSelected
                                      ? Border.all(color: Colors.blue, width: 2)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: shouldBeTransparent
                                    ? Opacity(
                                        opacity: 0.3,
                                        child: CardWidget(
                                          card: currentCard,
                                          isSelectable: false,
                                          isSelected: false,
                                          size: 40,
                                        ),
                                      )
                                    : isSelectable
                                        ? Draggable<DraggableCardData>(
                                            onDragStarted: () {
                                              // 設置拖動狀態，標記從當前卡片開始的所有卡片為拖動狀態
                                              setState(() {
                                                draggingCardIndex = cardIndex;
                                              });
                                            },
                                            onDragEnd: (_) {
                                              // 重置拖動狀態
                                              setState(() {
                                                draggingCardIndex = null;
                                              });
                                            },
                                            onDraggableCanceled: (_, __) {
                                              // 重置拖動狀態
                                              setState(() {
                                                draggingCardIndex = null;
                                              });
                                            },
                                            // 拖動數據
                                            data: DraggableCardData(
                                              card: currentCard,
                                              location: location,
                                              subIndex: cardIndex,
                                            ),
                                            // 自定義拖動時的反饋部件 - 顯示整個序列
                                            feedback: _buildCardSequence(
                                              cardIndex,
                                              column.length,
                                              20.0, // 使用較小的固定偏移量，使拖動時更緊湊
                                              isSelected,
                                            ),
                                            // 拖動時原位置不顯示任何內容，因為我們已經在Stack中處理了透明度
                                            childWhenDragging: const SizedBox(),
                                            // 卡片本身
                                            child: CardWidget(
                                              card: currentCard,
                                              isSelectable: isSelectable,
                                              isSelected: isSelected,
                                              size: 40,
                                              location: location,
                                              subIndex: cardIndex,
                                            ),
                                          )
                                        : CardWidget(
                                            card: currentCard,
                                            isSelectable: isSelectable,
                                            isSelected: isSelected,
                                            size: 40,
                                            location: location,
                                            subIndex: cardIndex,
                                          ),
                              ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建拖拽时显示的卡片序列
  Widget _buildCardSequence(
      int startIndex, int totalCards, double offset, bool isSelected) {
    // 计算序列中的卡片数量
    int cardCount = totalCards - startIndex;

    // 创建序列堆叠
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 40.0, // 固定寬度與卡片寬度相同
        height: 60.0 + (cardCount - 1) * offset, // 計算總高度
        child: Stack(
          clipBehavior: Clip.none,
          children: List.generate(cardCount, (index) {
            int actualIndex = startIndex + index;
            return Positioned(
              top: index * offset, // 固定的小偏移量，让拖动时紧凑一些
              child: CardWidget(
                card: widget.column[actualIndex],
                isSelectable: true,
                isSelected: isSelected && index == 0, // 只高亮第一张牌
                size: 40,
              ),
            );
          }),
        ),
      ),
    );
  }

  /// 處理卡片點擊
  void _handleCardTap(int cardIndex, WidgetRef ref) {
    final gameState = ref.read(gameNotifierProvider);
    final gameNotifier = ref.read(gameNotifierProvider.notifier);

    domain.Card card = widget.column[cardIndex];

    if (gameState.selectedCard == null) {
      // 如果沒有選中的卡片，嘗試選擇這張卡片
      if (_isCardSelectable(cardIndex)) {
        final location = CardLocation(
          type: CardLocationType.column,
          index: widget.columnIndex,
          subIndex: cardIndex,
        );

        gameNotifier.selectCard(card, location);
      } else {
        // 顯示提示，不可選擇
        _showInvalidSelectionMessage(ref.context);
      }
    } else if (gameState.selectedCardLocation?.type ==
            CardLocationType.column &&
        gameState.selectedCardLocation?.index == widget.columnIndex &&
        gameState.selectedCardLocation?.subIndex == cardIndex) {
      // 如果點擊了已選中的卡片，取消選擇
      gameNotifier.clearSelection();
    } else if (cardIndex == widget.column.length - 1 &&
        gameState.selectedCard != null) {
      // 如果點擊了列頂部的卡片且有選中的卡片，檢查是否可以移動到這張卡片上
      domain.Card selectedCard = gameState.selectedCard!;

      if (selectedCard.canPlaceOnCard(card)) {
        // 如果可以移動，則嘗試移動到這列
        final toLocation = CardLocation(
          type: CardLocationType.column,
          index: widget.columnIndex,
        );

        gameNotifier.tryMoveCard(gameState.selectedCardLocation!, toLocation);
      } else if (_isCardSelectable(cardIndex)) {
        // 如果不能移動，但這張卡是可選的，則選擇這張新卡片
        final location = CardLocation(
          type: CardLocationType.column,
          index: widget.columnIndex,
          subIndex: cardIndex,
        );

        gameNotifier.selectCard(card, location);
      } else {
        // 嘗試移動到這列
        final toLocation = CardLocation(
          type: CardLocationType.column,
          index: widget.columnIndex,
        );

        gameNotifier.tryMoveCard(gameState.selectedCardLocation!, toLocation);
      }
    } else if (_isCardSelectable(cardIndex)) {
      // 如果點擊了另一張可選的牌，直接選取新的牌
      final location = CardLocation(
        type: CardLocationType.column,
        index: widget.columnIndex,
        subIndex: cardIndex,
      );

      gameNotifier.selectCard(card, location);
    } else {
      // 如果點擊了一個位置（列），嘗試移動到這列
      final toLocation = CardLocation(
        type: CardLocationType.column,
        index: widget.columnIndex,
      );

      gameNotifier.tryMoveCard(gameState.selectedCardLocation!, toLocation);
    }
  }

  /// 判斷卡片是否可選擇
  bool _isCardSelectable(int cardIndex) {
    // 頂部卡片總是可選擇的
    if (cardIndex == widget.column.length - 1) return true;

    // 檢查從此卡片到頂部是否形成有效序列
    bool formsValidSequence = true;
    for (int i = cardIndex; i < widget.column.length - 1; i++) {
      if (!_isValidSequence(widget.column[i], widget.column[i + 1])) {
        formsValidSequence = false;
        break;
      }
    }

    return formsValidSequence;
  }

  /// 檢查兩張卡片是否形成有效序列（不同顏色且連續遞減）
  bool _isValidSequence(domain.Card lower, domain.Card upper) {
    return lower.value == upper.value + 1 && lower.isRed != upper.isRed;
  }

  /// 判斷卡片是否被選中
  bool _isCardSelected(int cardIndex, GameState gameState) {
    return gameState.selectedCardLocation?.type == CardLocationType.column &&
        gameState.selectedCardLocation?.index == widget.columnIndex &&
        gameState.selectedCardLocation?.subIndex != null &&
        cardIndex >= gameState.selectedCardLocation!.subIndex!;
  }

  /// 顯示無效選擇提示
  void _showInvalidSelectionMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('只能選擇形成有效序列的牌（不同顏色且連續遞減）'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
