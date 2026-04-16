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


  if (!AppConstants.useMock) {
    sl.registerLazySingleton<ApiClient>(() => ApiClient());
  }



  sl.registerLazySingleton<KanbanRemoteDataSource>(
    () => AppConstants.useMock
        ? KanbanMockDataSource()
        : KanbanRemoteDataSourceImpl(sl<ApiClient>()),
  );


  sl.registerLazySingleton<KanbanRepository>(
    () => KanbanRepositoryImpl(sl()),
  );


  sl.registerLazySingleton(() => GetIndicatorsUseCase(sl()));
  sl.registerLazySingleton(() => SaveIndicatorFieldUseCase(sl()));


  sl.registerFactory(
    () => KanbanBloc(
      getIndicatorsUseCase: sl(),
      saveIndicatorFieldUseCase: sl(),
    ),
  );
}
