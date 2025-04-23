import '../entities/game_state.dart';

/// 遊戲倉庫接口
/// 定義訪問和操作遊戲數據的方法
abstract class GameRepository {
  /// 獲取新遊戲的初始狀態
  GameState getNewGameState();

  /// 移動卡片
  /// 從一個位置移動到另一個位置
  GameState moveCard(GameState state, CardLocation from, CardLocation to);

  /// 自動收集可以移到基礎堆的卡片
  GameState autoCollectToFoundation(GameState state);

  /// 判斷移動是否有效
  bool isValidMove(GameState state, CardLocation from, CardLocation to);
}
