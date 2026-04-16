import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/indicator.dart';
import '../../domain/repositories/kanban_repository.dart';
import '../datasources/kanban_remote_datasource.dart';

class KanbanRepositoryImpl implements KanbanRepository {
  final KanbanRemoteDataSource remoteDataSource;

  const KanbanRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Indicator>>> getIndicators() async {
    try {
      final indicators = await remoteDataSource.getIndicators();
      return Right(indicators);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Неожиданная ошибка: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveIndicatorField({
    required int indicatorToMoId,
    required String fieldName,
    required String fieldValue,
  }) async {
    try {
      await remoteDataSource.saveIndicatorField(
        indicatorToMoId: indicatorToMoId,
        fieldName: fieldName,
        fieldValue: fieldValue,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Неожиданная ошибка: $e'));
    }
  }
}
