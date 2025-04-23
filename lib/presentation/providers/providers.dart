import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_history_datasource.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/auto_collect_usecase.dart';
import '../../domain/usecases/manage_history_usecase.dart';
import '../../domain/usecases/move_card_usecase.dart';
import '../../domain/usecases/start_game_usecase.dart';

part 'providers.g.dart';

/// SharedPreferences 提供者
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// 本地歷史記錄數據源提供者
@riverpod
Future<LocalHistoryDataSource> localHistoryDataSource(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LocalHistoryDataSourceImpl(prefs);
}

/// 遊戲倉庫提供者
@riverpod
GameRepository gameRepository(Ref ref) {
  return GameRepositoryImpl();
}

/// 歷史記錄倉庫提供者
@riverpod
Future<HistoryRepository> historyRepository(Ref ref) async {
  final dataSource = await ref.watch(localHistoryDataSourceProvider.future);
  return HistoryRepositoryImpl(dataSource);
}

/// 開始遊戲用例提供者
@riverpod
StartGameUseCase startGameUseCase(Ref ref) {
  final repository = ref.watch(gameRepositoryProvider);
  return StartGameUseCase(repository);
}

/// 移動卡片用例提供者
@riverpod
MoveCardUseCase moveCardUseCase(Ref ref) {
  final repository = ref.watch(gameRepositoryProvider);
  return MoveCardUseCase(repository);
}

/// 自動收集用例提供者
@riverpod
AutoCollectUseCase autoCollectUseCase(Ref ref) {
  final repository = ref.watch(gameRepositoryProvider);
  return AutoCollectUseCase(repository);
}

/// 管理歷史記錄用例提供者
@riverpod
Future<ManageHistoryUseCase> manageHistoryUseCase(Ref ref) async {
  final repository = await ref.watch(historyRepositoryProvider.future);
  return ManageHistoryUseCase(repository);
}
