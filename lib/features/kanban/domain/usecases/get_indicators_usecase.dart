import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/indicator.dart';
import '../repositories/kanban_repository.dart';

class GetIndicatorsUseCase {
  final KanbanRepository repository;

  const GetIndicatorsUseCase(this.repository);

  Future<Either<Failure, List<Indicator>>> call() {
    return repository.getIndicators();
  }
}
