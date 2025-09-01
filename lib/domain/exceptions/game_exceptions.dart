/// 遊戲相關異常定義

/// 無效移動異常
class InvalidMoveException implements Exception {
  final String message;

  InvalidMoveException(this.message);

  @override
  String toString() => 'InvalidMoveException: $message';
}