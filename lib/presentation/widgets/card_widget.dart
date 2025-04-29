import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/card.dart' as domain;
import '../../domain/entities/game_state.dart';

/// 卡片資料模型，用於拖放
class DraggableCardData {
  final domain.Card card;
  final CardLocation location;
  final int? subIndex; // 用於列中的子索引

  DraggableCardData({
    required this.card,
    required this.location,
    this.subIndex,
  });
}

/// 卡片小部件
class CardWidget extends ConsumerWidget {
  /// 卡片實體
  final domain.Card card;

  /// 是否可選擇
  final bool isSelectable;

  /// 是否選中
  final bool isSelected;

  /// 卡片尺寸
  final double size;

  /// 卡片位置
  final CardLocation? location;

  /// 卡片子索引
  final int? subIndex;

  /// 是否可拖動
  final bool isDraggable;

  const CardWidget({
    super.key,
    required this.card,
    this.isSelectable = true,
    this.isSelected = false,
    this.size = 70.0,
    this.location,
    this.subIndex,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 獲取屏幕寬度
    final screenWidth = MediaQuery.of(context).size.width;
    // 判斷是否為手機螢幕（寬度小於600）
    final isMobileScreen = screenWidth < 600;

    // 卡片內容
    Widget cardContent = Container(
      width: size,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Stack(
        children: [
          // 左上角數字 - 始終顯示
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28,
              ),
            ),
          ),

          // 右下角數字 - 始終顯示
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28,
              ),
            ),
          ),

          // 只在非手機屏幕上顯示左上花色符號
          if (!isMobileScreen)
            Positioned(
              top: 2 + size * 0.28,
              left: 4,
              child: Text(
                card.suit.symbol,
                style: TextStyle(
                  color: card.isRed ? Colors.red : Colors.black,
                  fontSize: size * 0.28,
                ),
              ),
            ),

          // 中間花色（始終顯示）
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontSize:
                    isMobileScreen ? size * 0.45 : size * 0.5, // 進一步縮小手機版中央花色
              ),
            ),
          ),

          // 可選擇指示器
          if (isSelectable)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    // 如果不可拖動或沒有位置信息，直接返回卡片
    if (!isDraggable || location == null || !isSelectable) {
      return cardContent;
    }

    // 返回可拖動的卡片
    return Draggable<DraggableCardData>(
      // 拖動數據
      data: DraggableCardData(
        card: card,
        location: location!,
        subIndex: subIndex,
      ),
      // 拖動時的反饋部件（半透明）
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: Opacity(
            opacity: 0.8,
            child: cardContent,
          ),
        ),
      ),
      // 拖動時保留原位置的部件
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      // 拖動時的占位部件
      dragAnchorStrategy: (draggable, context, position) {
        // 返回卡片中心位置作為拖動錨點
        return Offset(size / 2, size * 0.75);
      },
      // 卡片本身
      child: cardContent,
    );
  }
}

/// 簡化版卡片小部件（適用於基礎堆和自由單元格）
class CardWidgetSimple extends StatelessWidget {
  final domain.Card card;
  final double size;
  final bool isSelected;
  final bool isDraggable;
  final CardLocation? location;

  const CardWidgetSimple({
    super.key,
    required this.card,
    this.size = 60.0,
    this.isSelected = false,
    this.isDraggable = false,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: size,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Stack(
        children: [
          // 左上角數字
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28,
              ),
            ),
          ),
          // 中間花色
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontSize: size * 0.45,
              ),
            ),
          ),
          // 右下角數字
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(
              card.rank.symbol,
              style: TextStyle(
                color: card.isRed ? Colors.red : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.28,
              ),
            ),
          ),
        ],
      ),
    );

    // 如果不可拖動或沒有位置信息
    if (!isDraggable || location == null) {
      return cardContent;
    }

    // 返回可拖動的卡片
    return Draggable<DraggableCardData>(
      data: DraggableCardData(
        card: card,
        location: location!,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: Opacity(
            opacity: 0.8,
            child: cardContent,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: cardContent,
      ),
      dragAnchorStrategy: (draggable, context, position) {
        return Offset(size / 2, size * 0.75);
      },
      child: cardContent,
    );
  }
}
