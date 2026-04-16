import 'package:flutter_test/flutter_test.dart';

import 'package:mini_trello/features/kanban/data/datasources/kanban_mock_datasource.dart';

void main() {
  late KanbanMockDataSource datasource;

  setUp(() => datasource = KanbanMockDataSource());

  test('getIndicators returns a non-empty list', () async {
    final result = await datasource.getIndicators();
    expect(result, isNotEmpty);
  });

  test('contains both folder items and task items', () async {
    final items = await datasource.getIndicators();

    // Folder items: indicator_to_mo_id is referenced as parent_id by other items
    final allParentIds = items
        .where((i) => i.parentId != null)
        .map((i) => i.parentId!)
        .toSet();
    final folderIds =
        items.map((i) => i.indicatorToMoId).toSet().intersection(allParentIds);

    expect(folderIds, isNotEmpty, reason: 'Expected at least one folder item');

    final tasks = items.where((i) => i.parentId != null).toList();
    expect(tasks, isNotEmpty, reason: 'Expected at least one task item');
  });

  test('saveIndicatorField updates parent_id in-memory', () async {
    final before = await datasource.getIndicators();
    final task = before.firstWhere((i) => i.parentId != null);
    final originalParent = task.parentId!;

    // Find a different folder to move it to
    final otherFolder = before
        .firstWhere((i) => i.indicatorToMoId != originalParent && i.parentId == null);

    await datasource.saveIndicatorField(
      indicatorToMoId: task.indicatorToMoId,
      fieldName: 'parent_id',
      fieldValue: otherFolder.indicatorToMoId.toString(),
    );

    final after = await datasource.getIndicators();
    final updated = after.firstWhere((i) => i.indicatorToMoId == task.indicatorToMoId);
    expect(updated.parentId, otherFolder.indicatorToMoId);
  });

  test('saveIndicatorField updates order in-memory', () async {
    final before = await datasource.getIndicators();
    final task = before.firstWhere((i) => i.parentId != null);

    await datasource.saveIndicatorField(
      indicatorToMoId: task.indicatorToMoId,
      fieldName: 'order',
      fieldValue: '99',
    );

    final after = await datasource.getIndicators();
    final updated = after.firstWhere((i) => i.indicatorToMoId == task.indicatorToMoId);
    expect(updated.order, 99);
  });

  test('saveIndicatorField with unknown id does not throw', () async {
    await expectLater(
      datasource.saveIndicatorField(
        indicatorToMoId: 0, // non-existent
        fieldName: 'parent_id',
        fieldValue: '100',
      ),
      completes,
    );
  });

  test('getIndicators returns a copy — external mutations do not affect state',
      () async {
    final list1 = await datasource.getIndicators();
    list1.clear();

    final list2 = await datasource.getIndicators();
    expect(list2, isNotEmpty);
  });
}
