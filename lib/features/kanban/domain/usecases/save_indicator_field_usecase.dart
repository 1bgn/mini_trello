import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/kanban_repository.dart';

class SaveIndicatorFieldUseCase {
  final KanbanRepository repository;

  const SaveIndicatorFieldUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int indicatorToMoId,
    required Map<String, String> fields,
  }) {
    return repository.saveIndicatorField(
      indicatorToMoId: indicatorToMoId,
      fields: fields,
    );
  }
}
