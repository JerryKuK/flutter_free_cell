import '../entities/game_state.dart';
import '../repositories/game_repository.dart';

/// 開始遊戲用例
/// 負責創建新遊戲的初始狀態
class StartGameUseCase {
  final GameRepository _repository;

  StartGameUseCase(this._repository);

  /// 開始新遊戲
  GameState call() {
    return _repository.getNewGameState();
  }
}
