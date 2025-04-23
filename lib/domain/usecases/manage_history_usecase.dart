import '../entities/game_record.dart';
import '../repositories/history_repository.dart';

/// 管理歷史記錄用例
/// 負責遊戲歷史記錄的讀取、保存和清除
class ManageHistoryUseCase {
  final HistoryRepository _repository;

  ManageHistoryUseCase(this._repository);

  /// 獲取遊戲歷史記錄
  Future<List<GameRecord>> getGameHistory() {
    return _repository.getGameHistory();
  }

  /// 保存遊戲記錄
  Future<void> saveGameRecord(GameRecord record) {
    return _repository.saveGameRecord(record);
  }

  /// 清除所有遊戲歷史記錄
  Future<void> clearGameHistory() {
    return _repository.clearGameHistory();
  }

  /// 獲取排序後的歷史記錄
  ///
  /// [sortMethod] 排序方法
  /// 0 - 按日期排序（最新在前）
  /// 1 - 按完成時間排序（從短到長）
  /// 2 - 按移動次數排序（從少到多）
  Future<List<GameRecord>> getSortedHistory(int sortMethod) async {
    final history = await getGameHistory();
    final sortedHistory = List<GameRecord>.from(history);

    if (sortMethod == 1) {
      // 按完成時間排序
      sortedHistory.sort((a, b) {
        int timeCompare = a.duration.compareTo(b.duration);
        return timeCompare != 0 ? timeCompare : a.moves.compareTo(b.moves);
      });
    } else if (sortMethod == 2) {
      // 按移動次數排序
      sortedHistory.sort((a, b) {
        int movesCompare = a.moves.compareTo(b.moves);
        return movesCompare != 0
            ? movesCompare
            : a.duration.compareTo(b.duration);
      });
    } else {
      // 默認按日期排序
      sortedHistory.sort((a, b) => b.date.compareTo(a.date));
    }

    return sortedHistory;
  }
}
