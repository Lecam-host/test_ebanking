import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/light_app_bar.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/history_sections.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/send_transfer_page.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/widgets/status_icon.dart';

const _grey = Color(0xFF909090);

/// Historique lu dans la base du téléphone : il s'affiche sans réseau, avec
/// l'heure de sa dernière mise à jour.
///
/// D'après les écrans du kit : onglets de « Payment history », lignes
/// groupées par jour de « Transaction report ».
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    // État encore inconnu au démarrage : pas de bandeau affiché à tort.
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: lightAppBar(
        'Historique',
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => openSendTransfer(context, ref),
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

Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se déconnecter ?'),
      content: const Text(
        'L\'historique et le code secret seront effacés de ce téléphone. '
        'Il faudra un nouveau code SMS pour revenir.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(authNotifierProvider.notifier).signOut();
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      spacing: 12,
      children: [
        Icon(Icons.cloud_off_rounded, color: AppColors.primary),
        Expanded(
          child: Text(
            'Hors connexion : historique enregistré sur le téléphone.',
            style: TextStyle(color: AppColors.text, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _HistoryList extends ConsumerStatefulWidget {
  const _HistoryList({required this.history});

  final TransferHistory history;

  @override
  ConsumerState<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<_HistoryList> {
  // Simple état d'affichage : il reste sur cet écran. L'onglet étant gardé en
  // vie par la barre du bas, on retrouve le même onglet au retour.
  var _filter = HistoryFilter.all;

  Future<void> _refresh() async {
    final result = await ref.read(syncHistoryProvider)();
    // Session terminée (révoquée) : l'app repart sur la connexion, qui en
    // donne la raison. Parler de serveur injoignable serait faux.
    if (result case Err(failure: UnauthorizedFailure())) return;
    if (result is Err && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serveur injoignable : historique enregistré affiché.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final transfers = widget.history.transfers
        .where((transfer) => _filter.matches(transfer.status))
        .toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // Toujours défilable : « tirer pour rafraîchir » marche aussi sur une
        // liste vide.
        physics: const AlwaysScrollableScrollPhysics(),
        // En bas, la place du bouton flottant : il ne cache pas le dernier.
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
        children: [
          Row(
            spacing: 6,
            children: [
              const Icon(Icons.sync_rounded, size: 16, color: _grey),
              Text(
                updatedAgo(widget.history.lastSyncedAt, now),
                style: const TextStyle(color: _grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FilterTabs(
            selected: _filter,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          if (transfers.isEmpty) _Empty(filtered: _filter != HistoryFilter.all),
          for (final section in sectionsByDay(transfers, now)) ...[
            _SectionTitle(section.title),
            for (final (index, transfer) in section.transfers.indexed) ...[
              if (index > 0)
                const Divider(height: 1, color: AppColors.surfaceTint),
              _TransferRow(transfer),
            ],
          ],
        ],
      ),
    );
  }
}

/// Onglets du kit : indigo pour l'onglet choisi, lavande pour les autres.
/// Quatre parts égales plutôt qu'un défilement : aucun onglet caché sur un
/// petit écran.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final HistoryFilter selected;
  final ValueChanged<HistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final filter in HistoryFilter.values)
          Expanded(
            child: Material(
              color: filter == selected
                  ? AppColors.primary
                  : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => onSelected(filter),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  // Rétrécit le libellé plutôt que de le couper quand le
                  // téléphone affiche les textes en grand.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        color: filter == selected
                            ? Colors.white
                            : AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: _grey,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Une ligne du kit : pastille du statut, bénéficiaire et statut, montant et
/// heure.
class _TransferRow extends StatelessWidget {
  const _TransferRow(this.transfer);

  final Transfer transfer;

  @override
  Widget build(BuildContext context) {
    final unsuccessful = isUnsuccessful(transfer.status);
    return InkWell(
      onTap: () => context.go('/transfers/${transfer.idempotencyKey}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 16,
          children: [
            StatusIcon(transfer.status),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    transfer.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    statusLabel(transfer.status),
                    style: const TextStyle(color: _grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 2,
              children: [
                Text(
                  formatAmount(transfer.amount),
                  style: TextStyle(
                    // Barré et gris : échoué (remboursé) ou refusé (jamais
                    // débité), ce montant n'a pas quitté le compte.
                    color: unsuccessful ? _grey : AppColors.text,
                    decoration: unsuccessful
                        ? TextDecoration.lineThrough
                        : null,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatTime(transfer.createdAt),
                  style: const TextStyle(color: _grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});

  /// Vide à cause de l'onglet choisi, pas de l'historique.
  final bool filtered;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 64),
    child: Column(
      spacing: 12,
      children: [
        const Icon(
          Icons.receipt_long_rounded,
          size: 56,
          color: AppColors.placeholder,
        ),
        Text(
          filtered
              ? 'Aucun transfert dans cet onglet'
              : 'Aucun transfert pour l\'instant',
          style: const TextStyle(color: _grey, fontSize: 15),
        ),
      ],
    ),
  );
}
