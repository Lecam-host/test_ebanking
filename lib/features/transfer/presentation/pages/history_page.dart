import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// Historique lu dans la base du téléphone : il s'affiche sans réseau, avec
/// l'heure de sa dernière mise à jour.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    // État encore inconnu au démarrage : pas de bandeau affiché à tort.
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/send'),
        icon: const Icon(Icons.send),
        label: const Text('Nouveau transfert'),
      ),
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(
            child: switch (history.value) {
              final value? => _HistoryList(history: value),
              null when history.hasError => const Center(
                child: Text('Historique illisible'),
              ),
              null => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Hors connexion : historique enregistré sur le téléphone.',
        style: TextStyle(color: colors.onErrorContainer),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.history});

  final TransferHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();

    return RefreshIndicator(
      onRefresh: () async {
        final result = await ref.read(syncHistoryProvider)();
        if (result is Err && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Serveur injoignable : historique enregistré affiché.',
              ),
            ),
          );
        }
      },
      child: ListView(
        // Toujours défilable : « tirer pour rafraîchir » marche aussi sur une
        // liste vide.
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(updatedAgo(history.lastSyncedAt, now)),
          ),
          if (history.transfers.isEmpty)
            const ListTile(title: Text('Aucun transfert')),
          for (final transfer in history.transfers)
            ListTile(
              title: Text(transfer.recipientName),
              subtitle: Text(
                '${statusLabel(transfer.status)} · '
                '${formatDateTime(transfer.createdAt)}',
              ),
              trailing: Text(formatAmount(transfer.amount)),
              onTap: () => context.go('/transfers/${transfer.idempotencyKey}'),
            ),
        ],
      ),
    );
  }
}
