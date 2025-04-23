import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/card.dart' as domain;

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

  const CardWidget({
    super.key,
    required this.card,
    this.isSelectable = true,
    this.isSelected = false,
    this.size = 70.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 獲取屏幕寬度
    final screenWidth = MediaQuery.of(context).size.width;
    // 判斷是否為手機螢幕（寬度小於600）
    final isMobileScreen = screenWidth < 600;

    return Container(
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
  }
}
