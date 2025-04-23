import 'dart:developer' as developer;

import '../../domain/entities/card.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';

/// 遊戲倉庫實現
class GameRepositoryImpl implements GameRepository {
  @override
  GameState getNewGameState() {
    return GameState.newGame();
  }

  @override
  GameState moveCard(GameState state, CardLocation from, CardLocation to) {
    // 使用GameState的moveCard方法移動卡片
    return state.moveCard(from, to);
  }

  @override
  GameState autoCollectToFoundation(GameState state) {
    developer.log('開始自動收集卡片...');
    var newState = state;
    bool madeMove;
    int attempts = 0;
    const maxAttempts = 52; // 防止無限循環
    bool foundAnyMove = false;

    // 輸出初始狀態
    for (int i = 0; i < newState.foundation.length; i++) {
      developer.log('初始狀態：基礎堆 $i 有 ${newState.foundation[i].length} 張卡片');
      if (newState.foundation[i].isNotEmpty) {
        developer.log('頂部卡片是：${newState.foundation[i].last}');
      }
    }

    // 先定義花色與基礎堆的對應關係
    // foundation[0] -> 紅心 (heart)
    // foundation[1] -> 方塊 (diamond)
    // foundation[2] -> 黑桃 (spade)
    // foundation[3] -> 梅花 (club)
    final suitToFoundationMap = {
      CardSuit.heart: 0,
      CardSuit.diamond: 1,
      CardSuit.spade: 2,
      CardSuit.club: 3,
    };

    // 先處理所有的A，確保每種花色的A都放入對應的基礎堆
    developer.log('首先處理所有的A...');

    // 首先檢查列中是否有A
    for (int columnIndex = 0;
        columnIndex < newState.columns.length;
        columnIndex++) {
      if (newState.columns[columnIndex].isEmpty) continue;

      final card = newState.columns[columnIndex].last;
      if (card.rank == CardRank.ace) {
        developer.log('在列 $columnIndex 找到 A: $card');

        // 根據A的花色確定對應的基礎堆
        final foundationIndex = suitToFoundationMap[card.suit]!;
        developer.log('該A應該放入基礎堆 $foundationIndex (${card.suit.name})');

        // 嘗試放入對應的基礎堆
        if (card.canPlaceInFoundation(
            newState.foundation[foundationIndex], foundationIndex)) {
          developer.log('確認可以放入基礎堆 $foundationIndex');

          final fromLocation = CardLocation(
            type: CardLocationType.column,
            index: columnIndex,
            subIndex: newState.columns[columnIndex].length - 1,
          );

          final toLocation = CardLocation(
            type: CardLocationType.foundation,
            index: foundationIndex,
          );

          try {
            developer.log('執行移動卡片操作：從列 $columnIndex 到基礎堆 $foundationIndex');
            final tempState = newState;

            // 直接使用moveCard方法移動卡片，不需要先選擇卡片
            newState = newState.moveCard(fromLocation, toLocation);

            // 檢查移動是否成功
            if (newState == tempState) {
              developer.log('警告：moveCard 操作沒有產生新的狀態！');
            } else {
              developer.log('moveCard 操作成功產生了新的狀態');
            }

            // 檢查基礎堆是否更新
            if (newState.foundation[foundationIndex].isEmpty) {
              developer.log('錯誤：移動後基礎堆仍然為空！');
            } else {
              developer.log(
                  '移動後基礎堆 $foundationIndex 包含 ${newState.foundation[foundationIndex].length} 張卡片');
              developer
                  .log('頂部卡片是：${newState.foundation[foundationIndex].last}');
            }

            foundAnyMove = true;
            developer.log('成功將 ${card.toString()} 放入基礎堆 $foundationIndex');
          } catch (e) {
            developer.log('移動A失敗: $e');
          }
        }
      }
    }

    // 檢查自由單元格中是否有A
    for (int freeCellIndex = 0;
        freeCellIndex < newState.freeCells.length;
        freeCellIndex++) {
      if (newState.freeCells[freeCellIndex] == null) continue;

      final card = newState.freeCells[freeCellIndex]!;
      if (card.rank == CardRank.ace) {
        developer.log('在自由單元格 $freeCellIndex 找到 A: $card');

        // 根據A的花色確定對應的基礎堆
        final foundationIndex = suitToFoundationMap[card.suit]!;
        developer.log('該A應該放入基礎堆 $foundationIndex (${card.suit.name})');

        // 嘗試放入對應的基礎堆
        if (card.canPlaceInFoundation(
            newState.foundation[foundationIndex], foundationIndex)) {
          developer.log('確認可以放入基礎堆 $foundationIndex');

          final fromLocation = CardLocation(
            type: CardLocationType.freeCell,
            index: freeCellIndex,
          );

          final toLocation = CardLocation(
            type: CardLocationType.foundation,
            index: foundationIndex,
          );

          try {
            developer
                .log('執行移動卡片操作：從自由單元格 $freeCellIndex 到基礎堆 $foundationIndex');
            final tempState = newState;

            // 直接使用moveCard方法，不需要先選擇卡片
            newState = newState.moveCard(fromLocation, toLocation);

            // 檢查移動是否成功
            if (newState == tempState) {
              developer.log('警告：moveCard 操作沒有產生新的狀態！');
            } else {
              developer.log('moveCard 操作成功產生了新的狀態');
            }

            // 檢查基礎堆是否更新
            if (newState.foundation[foundationIndex].isEmpty) {
              developer.log('錯誤：移動後基礎堆仍然為空！');
            } else {
              developer.log(
                  '移動後基礎堆 $foundationIndex 包含 ${newState.foundation[foundationIndex].length} 張卡片');
              developer
                  .log('頂部卡片是：${newState.foundation[foundationIndex].last}');
            }

            foundAnyMove = true;
            developer.log('成功將 ${card.toString()} 放入基礎堆 $foundationIndex');
          } catch (e) {
            developer.log('移動A失敗: $e');
          }
        }
      }
    }

    // 嘗試多次移動其他牌，直到不能再移動
    developer.log('開始處理其他牌...');
    do {
      madeMove = false;
      attempts++;
      developer.log('嘗試第 $attempts 次');

      // 優先考慮點數從小到大 (2-K)
      for (var targetRank = 2; targetRank <= 13; targetRank++) {
        bool foundCardWithRank = false;
        developer.log('嘗試移動點數為 $targetRank 的牌');

        // 首先嘗試從列中收集指定點數的卡片
        for (int columnIndex = 0;
            columnIndex < newState.columns.length;
            columnIndex++) {
          if (newState.columns[columnIndex].isEmpty) continue;

          final card = newState.columns[columnIndex].last;

          // 確認卡片點數是當前優先級
          if (card.value != targetRank) continue;

          developer.log('在列 $columnIndex 找到點數為 $targetRank 的牌: $card');

          // 檢查是否可以放入對應花色的基礎堆
          final foundationIndex = suitToFoundationMap[card.suit]!;
          developer.log('該牌應放入基礎堆 $foundationIndex (${card.suit.name})');

          if (card.canPlaceInFoundation(
              newState.foundation[foundationIndex], foundationIndex)) {
            developer.log('可以放入基礎堆 $foundationIndex');

            // 創建位置對象
            final fromLocation = CardLocation(
              type: CardLocationType.column,
              index: columnIndex,
              subIndex: newState.columns[columnIndex].length - 1,
            );

            final toLocation = CardLocation(
              type: CardLocationType.foundation,
              index: foundationIndex,
            );

            // 移動卡片
            try {
              developer.log(
                  '執行移動卡片操作：從列 $columnIndex 到基礎堆 $foundationIndex，卡片：$card');
              final tempState = newState;

              // 直接使用moveCard方法，不需要先選擇卡片
              newState = newState.moveCard(fromLocation, toLocation);

              // 檢查移動是否成功
              if (newState == tempState) {
                developer.log('警告：moveCard 操作沒有產生新的狀態！');
              } else {
                developer.log('moveCard 操作成功產生了新的狀態');
              }

              // 檢查基礎堆是否更新
              developer.log(
                  '移動後基礎堆 $foundationIndex 包含 ${newState.foundation[foundationIndex].length} 張卡片');
              if (newState.foundation[foundationIndex].isNotEmpty) {
                developer
                    .log('頂部卡片是：${newState.foundation[foundationIndex].last}');
              }

              madeMove = true;
              foundAnyMove = true;
              foundCardWithRank = true;
              developer.log(
                  '成功將 ${card.toString()} 從列 $columnIndex 移動到基礎堆 $foundationIndex');
              break; // 我們只需要處理當前列的頂部卡片，找到後跳到下一列
            } catch (e) {
              developer.log('移動失敗: $e');
              continue;
            }
          }
        }

        // 如果列中沒有找到指定點數的卡片，嘗試從自由單元格
        if (!foundCardWithRank) {
          for (int freeCellIndex = 0;
              freeCellIndex < newState.freeCells.length;
              freeCellIndex++) {
            if (newState.freeCells[freeCellIndex] == null) continue;

            final card = newState.freeCells[freeCellIndex]!;

            // 確認卡片點數是當前優先級
            if (card.value != targetRank) continue;

            developer.log('在自由單元格 $freeCellIndex 找到點數為 $targetRank 的牌: $card');

            // 檢查是否可以放入對應花色的基礎堆
            final foundationIndex = suitToFoundationMap[card.suit]!;
            developer.log('該牌應放入基礎堆 $foundationIndex (${card.suit.name})');

            if (card.canPlaceInFoundation(
                newState.foundation[foundationIndex], foundationIndex)) {
              developer.log('可以放入基礎堆 $foundationIndex');

              // 創建位置對象
              final fromLocation = CardLocation(
                type: CardLocationType.freeCell,
                index: freeCellIndex,
              );

              final toLocation = CardLocation(
                type: CardLocationType.foundation,
                index: foundationIndex,
              );

              // 移動卡片
              try {
                developer.log(
                    '執行移動卡片操作：從自由單元格 $freeCellIndex 到基礎堆 $foundationIndex，卡片：$card');
                final tempState = newState;

                // 直接使用moveCard方法，不需要先選擇卡片
                newState = newState.moveCard(fromLocation, toLocation);

                // 檢查移動是否成功
                if (newState == tempState) {
                  developer.log('警告：moveCard 操作沒有產生新的狀態！');
                } else {
                  developer.log('moveCard 操作成功產生了新的狀態');
                }

                // 檢查基礎堆是否更新
                developer.log(
                    '移動後基礎堆 $foundationIndex 包含 ${newState.foundation[foundationIndex].length} 張卡片');
                if (newState.foundation[foundationIndex].isNotEmpty) {
                  developer.log(
                      '頂部卡片是：${newState.foundation[foundationIndex].last}');
                }

                madeMove = true;
                foundAnyMove = true;
                foundCardWithRank = true;
                developer.log(
                    '成功將 ${card.toString()} 從自由單元格 $freeCellIndex 移動到基礎堆 $foundationIndex');
                break; // 找到並處理一張自由單元格中的卡片後，繼續下一張
              } catch (e) {
                developer.log('移動失敗: $e');
                continue;
              }
            }
          }
        }

        // 如果找到了指定點數的牌並移動成功，從頭開始尋找更小點數的牌
        if (madeMove) break;
      }
    } while (madeMove && attempts < maxAttempts);

    // 最終狀態
    developer.log('自動收集完成，顯示最終狀態：');
    for (int i = 0; i < newState.foundation.length; i++) {
      developer.log('最終狀態：基礎堆 $i 有 ${newState.foundation[i].length} 張卡片');
      if (newState.foundation[i].isNotEmpty) {
        developer.log('頂部卡片是：${newState.foundation[i].last}');
      }
    }

    // 檢查遊戲是否完成
    if (newState.checkGameCompleted()) {
      developer.log('遊戲已完成！');
      newState = newState.copyWith(
        isGameCompleted: true,
        endTime: DateTime.now(),
      );
    }

    // 如果沒有任何卡片可以移動，返回一個帶有標記的狀態
    if (!foundAnyMove) {
      developer.log('沒有找到可以自動收集的卡片');
      return newState.copyWith(
        // 添加一個自定義標記表示沒有可移動的卡片
        moveCount: newState.moveCount,
      );
    }

    developer.log('自動收集完成，成功移動了卡片');
    return newState;
  }

  @override
  bool isValidMove(GameState state, CardLocation from, CardLocation to) {
    // 獲取起始位置的卡片
    Card? card;

    switch (from.type) {
      case CardLocationType.column:
        if (from.subIndex != null &&
            from.index < state.columns.length &&
            from.subIndex! < state.columns[from.index].length) {
          card = state.columns[from.index][from.subIndex!];
        }
        break;
      case CardLocationType.freeCell:
        if (from.index < state.freeCells.length) {
          card = state.freeCells[from.index];
        }
        break;
      case CardLocationType.foundation:
        if (from.index < state.foundation.length &&
            state.foundation[from.index].isNotEmpty) {
          card = state.foundation[from.index].last;
        }
        break;
      case CardLocationType.none:
        // none 類型沒有卡片
        break;
    }

    // 如果沒有找到卡片，移動無效
    if (card == null) return false;

    // 檢查目標位置是否可以放置卡片
    switch (to.type) {
      case CardLocationType.column:
        if (to.index >= state.columns.length) return false;

        // 空列可以放置任何卡片
        if (state.columns[to.index].isEmpty) return true;

        // 非空列需要檢查頂部卡片是否可以放置選中的卡片
        return card.canPlaceOnCard(state.columns[to.index].last);

      case CardLocationType.freeCell:
        if (to.index >= state.freeCells.length) return false;

        // 只能放置到空的自由單元格
        return state.freeCells[to.index] == null;

      case CardLocationType.foundation:
        if (to.index >= state.foundation.length) return false;

        // 檢查是否可以放入基礎堆
        return card.canPlaceInFoundation(state.foundation[to.index], to.index);

      case CardLocationType.none:
        // none 類型不能放置卡片
        return false;
    }
  }
}
