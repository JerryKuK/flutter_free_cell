import '../entities/game_record.dart';

/// 歷史記錄倉庫接口
/// 負責遊戲歷史記錄的存儲和檢索
abstract class HistoryRepository {
  /// 獲取所有遊戲歷史記錄
  Future<List<GameRecord>> getGameHistory();

  /// 保存遊戲記錄
  Future<void> saveGameRecord(GameRecord record);

  /// 清除所有遊戲歷史記錄
  Future<void> clearGameHistory();
}
