import '../entities/game_state.dart';
import '../repositories/game_repository.dart';

/// 自動收集用例
/// 負責自動將符合條件的卡片移動到基礎堆
class AutoCollectUseCase {
  final GameRepository _repository;

  AutoCollectUseCase(this._repository);

  /// 執行自動收集
  ///
  /// [state] 當前遊戲狀態
  ///
  /// 返回更新後的遊戲狀態
  GameState call(GameState state) {
    return _repository.autoCollectToFoundation(state);
  }
}
