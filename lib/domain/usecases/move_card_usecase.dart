import '../entities/game_state.dart';
import '../repositories/game_repository.dart';

/// 移動卡片用例
/// 負責處理卡片移動的業務邏輯
class MoveCardUseCase {
  final GameRepository _repository;

  MoveCardUseCase(this._repository);

  /// 移動卡片
  ///
  /// [state] 當前遊戲狀態
  /// [from] 卡片的起始位置
  /// [to] 卡片的目標位置
  ///
  /// 返回更新後的遊戲狀態，如果移動無效則拋出異常
  GameState call(GameState state, CardLocation from, CardLocation to) {
    if (!_repository.isValidMove(state, from, to)) {
      throw InvalidMoveException('無效的移動');
    }

    return _repository.moveCard(state, from, to);
  }
}

/// 無效移動異常
class InvalidMoveException implements Exception {
  final String message;

  InvalidMoveException(this.message);

  @override
  String toString() => 'InvalidMoveException: $message';
}

/// 將卡牌從一個位置移動到另一個位置
///
/// [from] 卡牌當前位置
/// [to] 卡牌目標位置
/// [state] 當前遊戲狀態
///
/// 返回更新後的遊戲狀態，如果移動無效則拋出異常

/// 將卡牌從一個位置移動到另一個位置
///
/// [from] 卡牌當前位置
/// [to] 卡牌目標位置
/// [state] 當前遊戲狀態
///
/// 返回更新後的遊戲狀態，如果移動無效則拋出異常
 