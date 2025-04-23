import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/game_record.dart';
import 'providers.dart';

part 'history_provider.g.dart';

/// 歷史記錄提供者
/// 負責管理遊戲歷史記錄
@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  Future<List<GameRecord>> build() async {
    final manageHistoryUseCase =
        await ref.watch(manageHistoryUseCaseProvider.future);
    return manageHistoryUseCase.getGameHistory();
  }

  /// 保存遊戲記錄
  Future<void> saveGameRecord(GameRecord record) async {
    final manageHistoryUseCase =
        await ref.read(manageHistoryUseCaseProvider.future);
    await manageHistoryUseCase.saveGameRecord(record);
    ref.invalidateSelf(); // 重新加載歷史記錄
  }

  /// 清除所有遊戲歷史記錄
  Future<void> clearGameHistory() async {
    final manageHistoryUseCase =
        await ref.read(manageHistoryUseCaseProvider.future);
    await manageHistoryUseCase.clearGameHistory();
    ref.invalidateSelf(); // 重新加載歷史記錄
  }

  /// 獲取排序後的歷史記錄
  ///
  /// [sortMethod] 排序方法
  /// 0 - 按日期排序（最新在前）
  /// 1 - 按完成時間排序（從短到長）
  /// 2 - 按移動次數排序（從少到多）
  Future<List<GameRecord>> getSortedHistory(int sortMethod) async {
    final manageHistoryUseCase =
        await ref.read(manageHistoryUseCaseProvider.future);
    return manageHistoryUseCase.getSortedHistory(sortMethod);
  }
}
