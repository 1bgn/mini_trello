import 'package:get_it/get_it.dart';
import '../../features/kanban/data/datasources/kanban_mock_datasource.dart';
import '../../features/kanban/data/datasources/kanban_remote_datasource.dart';
import '../../features/kanban/data/repositories/kanban_repository_impl.dart';
import '../../features/kanban/domain/repositories/kanban_repository.dart';
import '../../features/kanban/domain/usecases/get_indicators_usecase.dart';
import '../../features/kanban/domain/usecases/save_indicator_field_usecase.dart';
import '../../features/kanban/presentation/bloc/kanban_bloc.dart';
import '../constants/app_constants.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

void initDependencies() {
  // ── External ──────────────────────────────────────────────────────────────
  // ApiClient is only needed when running against the real API.
  if (!AppConstants.useMock) {
    sl.registerLazySingleton<ApiClient>(() => ApiClient());
  }

  // ── Data sources ──────────────────────────────────────────────────────────
  // Switch between real HTTP and in-memory mock via --dart-define=USE_MOCK=true
  sl.registerLazySingleton<KanbanRemoteDataSource>(
    () => AppConstants.useMock
        ? KanbanMockDataSource()
        : KanbanRemoteDataSourceImpl(sl<ApiClient>()),
  );

  // ── Repositories ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<KanbanRepository>(
    () => KanbanRepositoryImpl(sl()),
  );

  // ── Use cases ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetIndicatorsUseCase(sl()));
  sl.registerLazySingleton(() => SaveIndicatorFieldUseCase(sl()));

  // ── Bloc (factory → new instance per page) ────────────────────────────────
  sl.registerFactory(
    () => KanbanBloc(
      getIndicatorsUseCase: sl(),
      saveIndicatorFieldUseCase: sl(),
    ),
  );
}
