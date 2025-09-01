import '../../domain/entities/game_state.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/services/card_move_validation_service.dart';
import '../../domain/services/game_state_service.dart';

/// 遊戲倉庫實現
/// 負責基本的遊戲狀態資料存取，不包含業務邏輯
class GameRepositoryImpl implements GameRepository {
  final CardMoveValidationService _validationService;
  final GameStateService _gameStateService;

  GameRepositoryImpl()
      : _validationService = CardMoveValidationService(),
        _gameStateService = GameStateService(CardMoveValidationService());

  @override
  GameState getNewGameState() {
    return _gameStateService.createNewGame();
  }

  @override
  GameState moveCard(GameState state, CardLocation from, CardLocation to) {
    return _gameStateService.moveCard(state, from, to);
  }

  @override
  GameState autoCollectToFoundation(GameState state) {
    // 這個方法現在只是一個佔位符，實際邏輯移到了 AutoCollectService
    // 這裡可以直接呼叫 AutoCollectService，但為了避免循環依賴，
    // 我們將這個責任交給 use case
    throw UnsupportedError(
      'autoCollectToFoundation should be handled by AutoCollectUseCase');
  }

  @override
  bool isValidMove(GameState state, CardLocation from, CardLocation to) {
    return _validationService.isValidMove(state, from, to);
  }
}
