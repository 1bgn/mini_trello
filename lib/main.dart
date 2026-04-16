import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/kanban/presentation/pages/kanban_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KPI-Drive Kanban',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const KanbanPage(),
    );
  }
}
