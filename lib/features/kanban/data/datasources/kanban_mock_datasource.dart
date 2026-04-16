import '../models/indicator_model.dart';
import 'kanban_remote_datasource.dart';

/// In-memory mock that replaces the real HTTP datasource.
/// Activated via --dart-define=USE_MOCK=true  (or kUseMock in AppConstants).
///
/// Structure mirrors what the real API returns:
///   • Folder items  — indicator_to_mo_id is referenced as parent_id by tasks
///   • Task items    — have parent_id pointing to a folder
class KanbanMockDataSource implements KanbanRemoteDataSource {
  /// In-memory state so that drag-and-drop changes persist for the session.
  late final List<IndicatorModel> _store;

  KanbanMockDataSource() {
    _store = List.of(_seedData());
  }

  @override
  Future<List<IndicatorModel>> getIndicators() async {
    await _fakeDelay();
    return List.of(_store); // return a copy
  }

  @override
  Future<void> saveIndicatorField({
    required int indicatorToMoId,
    required Map<String, String> fields,
  }) async {
    await _fakeDelay(ms: 300);

    final idx = _store.indexWhere((i) => i.indicatorToMoId == indicatorToMoId);
    if (idx == -1) return; // unknown id — silently ignore

    var current = _store[idx];
    for (final entry in fields.entries) {
      current = switch (entry.key) {
        'parent_id' => current.copyWith(
            parentId: int.tryParse(entry.value) ?? current.parentId,
          ),
        'order' => current.copyWith(
            order: int.tryParse(entry.value) ?? current.order,
          ),
        _ => current,
      };
    }

    _store[idx] = current;
  }

  // ── Seed data ──────────────────────────────────────────────────────────────

  static List<IndicatorModel> _seedData() => [
        // ── Folders (their IDs appear as parent_id in tasks below) ────────
        _folder(318100, 'Новые задачи', order: 1),
        _folder(318200, 'В работе', order: 2),
        _folder(318300, 'На проверке', order: 3),
        _folder(318400, 'Выполнено', order: 4),

        // ── Новые задачи (318100) ─────────────────────────────────────────
        _task(319001, 318100, 'Настройка дашборда KPI', order: 1),
        _task(319002, 318100, 'Анализ показателей за квартал', order: 2),
        _task(319003, 318100, 'Обновить плановые значения МО', order: 3),
        _task(319004, 318100, 'Согласовать цели с руководством', order: 4),

        // ── В работе (318200) ─────────────────────────────────────────────
        _task(319101, 318200, 'Интеграция API с внешней системой', order: 1),
        _task(319102, 318200, 'Разработка отчёта по KPI сотрудников', order: 2),
        _task(319103, 318200, 'Доработка экрана канбан-доски', order: 3),

        // ── На проверке (318300) ──────────────────────────────────────────
        _task(319201, 318300, 'Проверка расчёта итоговых показателей', order: 1),
        _task(319202, 318300, 'Тестирование импорта данных из Excel', order: 2),

        // ── Выполнено (318400) ────────────────────────────────────────────
        _task(319301, 318400, 'Настройка уведомлений по email', order: 1),
        _task(319302, 318400, 'Миграция данных на новый сервер', order: 2),
        _task(319303, 318400, 'Документация по API v2', order: 3),
      ];

  static IndicatorModel _folder(int id, String name, {required int order}) =>
      IndicatorModel(
        indicatorToMoId: id,
        parentId: null, // folders have no parent
        name: name,
        order: order,
      );

  static IndicatorModel _task(
    int id,
    int parentId,
    String name, {
    required int order,
  }) =>
      IndicatorModel(
        indicatorToMoId: id,
        parentId: parentId,
        name: name,
        order: order,
      );

  static Future<void> _fakeDelay({int ms = 600}) =>
      Future<void>.delayed(Duration(milliseconds: ms));
}
