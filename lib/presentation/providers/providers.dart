import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_history_datasource.dart';
import '../../data/repositories/game_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/services/auto_collect_service.dart';
import '../../domain/services/card_move_validation_service.dart';
import '../../domain/services/game_state_service.dart';
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

/// 卡片移動驗證服務提供者
@riverpod
CardMoveValidationService cardMoveValidationService(Ref ref) {
  return CardMoveValidationService();
}

/// 遊戲狀態服務提供者
@riverpod
GameStateService gameStateService(Ref ref) {
  final validationService = ref.watch(cardMoveValidationServiceProvider);
  return GameStateService(validationService);
}

/// 自動收集服務提供者
@riverpod
AutoCollectService autoCollectService(Ref ref) {
  final validationService = ref.watch(cardMoveValidationServiceProvider);
  final gameStateService = ref.watch(gameStateServiceProvider);
  return AutoCollectService(validationService, gameStateService);
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
  final autoCollectService = ref.watch(autoCollectServiceProvider);
  return AutoCollectUseCase(autoCollectService);
}

/// 管理歷史記錄用例提供者
@riverpod
Future<ManageHistoryUseCase> manageHistoryUseCase(Ref ref) async {
  final repository = await ref.watch(historyRepositoryProvider.future);
  return ManageHistoryUseCase(repository);
}
