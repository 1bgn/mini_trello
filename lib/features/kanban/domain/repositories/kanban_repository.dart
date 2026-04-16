import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/indicator.dart';

abstract class KanbanRepository {
  Future<Either<Failure, List<Indicator>>> getIndicators();

  Future<Either<Failure, void>> saveIndicatorField({
    required int indicatorToMoId,
    required String fieldName,
    required String fieldValue,
  });
}
