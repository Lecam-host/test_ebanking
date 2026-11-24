import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// Détail d'un transfert, lu sur le téléphone : il se met à jour tout seul
/// quand la reprise ou la synchro change son statut.
class TransferDetailPage extends ConsumerWidget {
  const TransferDetailPage({super.key, required this.idempotencyKey});

  /// Identifiant local : il existe avant toute réponse du serveur.
  final String idempotencyKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value;
    final transfer = history?.transfers
        .where((t) => t.idempotencyKey == idempotencyKey)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Transfert')),
      body: switch (transfer) {
        null when history == null => const Center(
          child: CircularProgressIndicator(),
        ),
        null => const Center(child: Text('Transfert introuvable')),
        final transfer => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (transfer.status.needsReconciliation)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.hourglass_top),
                  title: Text('Vérification en cours'),
                  subtitle: Text(
                    'Le serveur n\'a pas encore confirmé ce transfert. '
                    'L\'app vérifie toute seule ; il ne partira jamais deux fois.',
                  ),
                ),
              ),
            _Field('Statut', statusLabel(transfer.status)),
            _Field('Montant', formatAmount(transfer.amount)),
            _Field('Bénéficiaire', transfer.recipientName),
            _Field('Numéro', transfer.recipientPhone),
            _Field('Créé le', formatDateTime(transfer.createdAt)),
            _Field('Mis à jour le', formatDateTime(transfer.updatedAt)),
            _Field('Référence serveur', transfer.serverId ?? '—'),
          ],
        ),
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text(label), subtitle: Text(value));
}
