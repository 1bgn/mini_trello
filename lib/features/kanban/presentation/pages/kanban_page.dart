import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/kanban_bloc.dart';
import '../bloc/kanban_event.dart';
import '../bloc/kanban_state.dart';
import '../widgets/kanban_board_widget.dart';

class KanbanPage extends StatelessWidget {
  const KanbanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<KanbanBloc>()..add(const LoadIndicatorsEvent()),
      child: const _KanbanPageView(),
    );
  }
}

class _KanbanPageView extends StatelessWidget {
  const _KanbanPageView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KanbanBloc, KanbanState>(
      listener: _handleListener,
      builder: _buildScaffold,
    );
  }

  void _handleListener(BuildContext context, KanbanState state) {
    if (state is KanbanSaveError) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSaveErrorSnackBar(context, state),
      );
    }
  }

  SnackBar _buildSaveErrorSnackBar(BuildContext context, KanbanSaveError state) {

    if (state.isPermissionError) {
      return SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      );
    }


    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Повторить',
        textColor: Colors.white,
        onPressed: () =>
            context.read<KanbanBloc>().add(const RefreshIndicatorsEvent()),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, KanbanState state) {
    return Scaffold(
      appBar: _KanbanAppBar(state: state),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, KanbanState state) {
    return switch (state) {
      KanbanInitial() => const SizedBox.shrink(),
      KanbanLoading() => const _LoadingView(),
      KanbanLoaded() => KanbanBoardWidget(state: state),
      KanbanSaveError(:final previousState) =>
        KanbanBoardWidget(state: previousState),
      KanbanError(:final message) => _ErrorView(
          message: message,
          onRetry: () =>
              context.read<KanbanBloc>().add(const LoadIndicatorsEvent()),
        ),
    };
  }
}

class _KanbanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final KanbanState state;

  const _KanbanAppBar({required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isBusy = switch (state) {
      KanbanLoading() => true,
      KanbanLoaded(:final isSaving) => isSaving,
      _ => false,
    };
    final loaded = state is KanbanLoaded ? state as KanbanLoaded : null;
    final indicatorCount = loaded?.indicators.length ?? 0;
    final columnCount = loaded?.columns.length ?? 0;

    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          border: Border(
            bottom: BorderSide(color: Color(0xFF333333), width: 1),
          ),
        ),
      ),
      title: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.cardBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'KPI-Drive',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (state is KanbanLoaded)
                Text(
                  '$columnCount колонок · $indicatorCount задач',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                )
              else
                const Text(
                  'Канбан-доска задач',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (isBusy)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.textSecondary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
          tooltip: 'Обновить данные',
          onPressed: isBusy
              ? null
              : () => context
                  .read<KanbanBloc>()
                  .add(const RefreshIndicatorsEvent()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primaryLight,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Загрузка задач…',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Подключение к KPI-Drive',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 52,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Не удалось загрузить данные',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Попробовать снова',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
