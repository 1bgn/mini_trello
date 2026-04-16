# mini_trello

Kanban-доска для работы с индикаторами KPI-Drive. Позволяет просматривать задачи по колонкам и перетаскивать карточки между ними с сохранением изменений через API.

## Возможности

- Загрузка индикаторов с сервера KPI-Drive (`get_mo_indicators`)
- Группировка задач по колонкам (родительским индикаторам)
- Drag & Drop карточек внутри колонки и между колонками
- Оптимистичное обновление UI: карточка перемещается сразу, при ошибке — откатывается
- Карточки с `allow_edit: false` показываются с иконкой замка; перетаскивание отменяется с уведомлением
- Сохранение нового `parent_id` и `order` через `save_indicator_instance_field`
- Тёмная тема

## Структура проекта

```
lib/
├── core/
│   ├── constants/     # AppConstants: baseUrl, токен, период, пути
│   ├── di/            # get_it — регистрация зависимостей
│   ├── errors/        # Failures, Exceptions
│   ├── network/       # ApiClient (Dio) + интерцепторы (auth, retry, logging)
│   └── theme/         # AppTheme, AppColors
└── features/kanban/
    ├── data/
    │   ├── datasources/   # KanbanRemoteDataSource, KanbanMockDataSource
    │   ├── models/        # IndicatorModel (fromJson / copyWith)
    │   └── repositories/  # KanbanRepositoryImpl
    ├── domain/
    │   ├── entities/      # Indicator
    │   ├── repositories/  # KanbanRepository (абстракция)
    │   └── usecases/      # GetIndicatorsUseCase, SaveIndicatorFieldUseCase
    └── presentation/
        ├── bloc/          # KanbanBloc, KanbanEvent, KanbanState (freezed)
        ├── pages/         # KanbanPage
        └── widgets/       # KanbanBoardWidget, KanbanColumnWidget, KanbanCardWidget
```

## Зависимости

| Пакет | Назначение |
|---|---|
| `flutter_bloc` | BLoC state management |
| `freezed` / `freezed_annotation` | Sealed union states & events |
| `dio` | HTTP-клиент |
| `dartz` | `Either` для обработки ошибок |
| `get_it` | Dependency injection |
| `equatable` | Value equality |

## Запуск

### Обязательное требование для веб (CORS)

API KPI-Drive возвращает заголовок `Access-Control-Allow-Origin: https://admin.dev.kpi-drive.ru`, поэтому браузер блокирует запросы с `localhost`. Для локальной разработки необходимо запускать Chrome с отключённой проверкой CORS:

```bash
flutter run -d chrome --web-browser-flag --disable-web-security
```

> **Внимание:** флаг `--disable-web-security` делает браузер небезопасным. Используйте только для разработки и не открывайте в этом окне посторонние сайты.

### VS Code

В репозитории есть готовые конфигурации запуска (`.vscode/launch.json`):

- **Web (CORS disabled)** — Chrome с `--disable-web-security`
- **Web (mock data)** — локальные моковые данные без запросов к API
- **macOS** — нативное приложение, CORS не применяется

### Запуск на macOS (без ограничений CORS)

```bash
flutter run -d macos
```

### Запуск с моковыми данными

```bash
flutter run --dart-define=USE_MOCK=true
```

### Генерация кода (freezed)

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Конфигурация API

Настройки находятся в `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl      = 'https://api.dev.kpi-drive.ru/_api';
static const String bearerToken  = '5c3964b8e3ee4755f2cc0febb851e2f8';
static const String periodStart  = '2026-04-01';
static const String periodEnd    = '2026-04-30';
static const String authUserId   = '40';
```

> Период должен быть открытым для записи. Закрытые периоды возвращают ошибку в теле ответа при попытке сохранения.

## Тесты

```bash
flutter test
```

Покрыты: BLoC (загрузка, ошибки, перемещение карточек), удалённый datasource (парсинг ответа, обработка ошибок Dio), мок-datasource (мутации в памяти).
