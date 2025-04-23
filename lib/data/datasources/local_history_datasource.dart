import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/game_record.dart';

/// 本地歷史記錄數據源接口
abstract class LocalHistoryDataSource {
  /// 獲取所有遊戲歷史記錄
  Future<List<GameRecord>> getGameHistory();

  /// 保存遊戲記錄
  Future<void> saveGameRecord(GameRecord record);

  /// 清除所有遊戲歷史記錄
  Future<void> clearGameHistory();
}

/// 本地歷史記錄數據源實現
/// 使用SharedPreferences存儲歷史記錄
class LocalHistoryDataSourceImpl implements LocalHistoryDataSource {
  final SharedPreferences _prefs;

  /// 歷史記錄存儲鍵
  static const String _historyKey = 'game_history';

  /// 最大記錄數量
  static const int _maxRecords = 20;

  LocalHistoryDataSourceImpl(this._prefs);

  @override
  Future<List<GameRecord>> getGameHistory() async {
    final historyJson = _prefs.getStringList(_historyKey) ?? [];

    try {
      return historyJson
          .map((json) => GameRecord.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      // 如果解析失敗，返回空列表
      return [];
    }
  }

  @override
  Future<void> saveGameRecord(GameRecord record) async {
    // 獲取現有記錄
    final history = await getGameHistory();

    // 添加新記錄
    history.add(record);

    // 如果超過最大數量，移除最舊的記錄
    if (history.length > _maxRecords) {
      // 按日期排序，保留最新的記錄
      history.sort((a, b) => b.date.compareTo(a.date));
      history.removeLast();
    }

    // 將記錄轉換為JSON字串列表
    final historyJson =
        history.map((record) => jsonEncode(record.toJson())).toList();

    // 保存到SharedPreferences
    await _prefs.setStringList(_historyKey, historyJson);
  }

  @override
  Future<void> clearGameHistory() async {
    await _prefs.remove(_historyKey);
  }
}
