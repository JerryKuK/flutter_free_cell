import '../entities/game_state.dart';
import '../services/auto_collect_service.dart';

/// 自動收集用例
/// 負責自動將符合條件的卡片移動到基礎堆
class AutoCollectUseCase {
  final AutoCollectService _autoCollectService;

  AutoCollectUseCase(this._autoCollectService);

  /// 執行自動收集
  ///
  /// [state] 當前遊戲狀態
  ///
  /// 返回更新後的遊戲狀態，以及收集結果信息
  AutoCollectResult call(GameState state) {
    final initialFoundationCount = _getTotalFoundationCards(state);
    final newState = _autoCollectService.autoCollect(state);
    final finalFoundationCount = _getTotalFoundationCards(newState);
    
    final cardsCollected = finalFoundationCount - initialFoundationCount;
    final hasCollectableCards = _autoCollectService.hasAutoCollectableCards(newState);
    
    return AutoCollectResult(
      state: newState,
      cardsCollected: cardsCollected,
      hasMoreCollectableCards: hasCollectableCards,
    );
  }

  /// 檢查是否有可自動收集的卡片
  ///
  /// [state] 遊戲狀態
  ///
  /// 返回 true 如果有可自動收集的卡片
  bool hasAutoCollectableCards(GameState state) {
    return _autoCollectService.hasAutoCollectableCards(state);
  }

  /// 計算基礎堆中的總卡片數
  ///
  /// [state] 遊戲狀態
  ///
  /// 返回基礎堆中的總卡片數
  int _getTotalFoundationCards(GameState state) {
    return state.foundation.fold(0, (sum, pile) => sum + pile.length);
  }
}

/// 自動收集結果
class AutoCollectResult {
  /// 更新後的遊戲狀態
  final GameState state;
  
  /// 此次收集的卡片數量
  final int cardsCollected;
  
  /// 是否還有更多可收集的卡片
  final bool hasMoreCollectableCards;

  const AutoCollectResult({
    required this.state,
    required this.cardsCollected,
    required this.hasMoreCollectableCards,
  });

  /// 是否成功收集了卡片
  bool get hasCollectedCards => cardsCollected > 0;
}
