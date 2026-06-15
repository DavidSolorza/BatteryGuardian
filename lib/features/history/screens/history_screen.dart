import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../providers/history_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../widgets/history_list_item.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadSessions();
    });
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          'Se eliminarán todas las sesiones de carga guardadas. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<HistoryProvider>().clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Consumer<HistoryProvider>(
      builder: (context, history, _) {
        if (history.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 4,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 140, borderRadius: 20),
            ),
          );
        }

        if (history.error != null) {
          return ErrorState(
            message: history.error!,
            onRetry: history.refresh,
          );
        }

        if (history.isEmpty) {
          return EmptyState(
            icon: Icons.history,
            title: 'Sin historial de cargas',
            message:
                'Conecta tu dispositivo al cargador para registrar sesiones '
                'automáticamente, incluso con la app cerrada.',
            action: FilledButton.icon(
              onPressed: history.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: history.refresh,
          child: ResponsiveContent(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: history.sessions.length + 1,
              separatorBuilder: (_, index) =>
                  index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${history.sessions.length} sesiones',
                          style: textStyles.titleLarge,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmClear(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Borrar todo'),
                      ),
                    ],
                  );
                }

                return HistoryListItem(
                  session: history.sessions[index - 1],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
