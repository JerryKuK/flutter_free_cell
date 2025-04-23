import '../../domain/entities/game_record.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local_history_datasource.dart';

/// 歷史記錄倉庫實現
class HistoryRepositoryImpl implements HistoryRepository {
  final LocalHistoryDataSource _dataSource;

  HistoryRepositoryImpl(this._dataSource);

  @override
  Future<List<GameRecord>> getGameHistory() async {
    return await _dataSource.getGameHistory();
  }

  @override
  Future<void> saveGameRecord(GameRecord record) async {
    await _dataSource.saveGameRecord(record);
  }

  @override
  Future<void> clearGameHistory() async {
    await _dataSource.clearGameHistory();
  }
}
