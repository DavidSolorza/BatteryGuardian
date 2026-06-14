import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/history_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
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

  @override
  Widget build(BuildContext context) {
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
                'Conecta tu dispositivo al cargador para registrar sesiones automáticamente.',
            action: FilledButton.icon(
              onPressed: history.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: history.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: history.sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return HistoryListItem(session: history.sessions[index]);
            },
          ),
        );
      },
    );
  }
}
