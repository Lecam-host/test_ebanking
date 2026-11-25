import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/light_app_bar.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/history_sections.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/widgets/status_icon.dart';

const _grey = Color(0xFF909090);

/// Détail d'un transfert, lu sur le téléphone : il se met à jour tout seul
/// quand la reprise, la synchro ou une notification change son statut.
///
/// D'après l'écran « Detail payment » du kit : le statut et ce qu'il veut
/// dire pour l'argent du client, puis un reçu.
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
      appBar: lightAppBar('Détail du transfert'),
      body: switch (transfer) {
        null when history == null => const Center(
          child: CircularProgressIndicator(),
        ),
        null => const Center(child: Text('Transfert introuvable')),
        final transfer => ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            _StatusHeader(transfer),
            const SizedBox(height: 24),
            _Receipt(
              transfer: transfer,
              senderPhone: ref.watch(currentPhoneProvider) ?? '',
            ),
          ],
        ),
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader(this.transfer);

  final Transfer transfer;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      StatusIcon(transfer.status, size: 64),
      const SizedBox(height: 12),
      Text(
        statusLabel(transfer.status),
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        statusExplanation(transfer.status),
        textAlign: TextAlign.center,
        style: const TextStyle(color: _grey, fontSize: 14, height: 1.4),
      ),
    ],
  );
}

/// Reçu du kit : carte blanche, lignes libellé / valeur, pointillés, total.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.transfer, required this.senderPhone});

  final Transfer transfer;
  final String senderPhone;

  @override
  Widget build(BuildContext context) {
    final unsuccessful = isUnsuccessful(transfer.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Reçu',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _Line('De', maskPhone(senderPhone)),
          _Line('À', transfer.recipientName),
          _Line('Numéro', formatPhone(transfer.recipientPhone)),
          _Line('Créé le', formatDateTime(transfer.createdAt)),
          _Line('Mis à jour le', formatDateTime(transfer.updatedAt)),
          // Pas encore de référence tant que le serveur n'a rien confirmé :
          // seule la clé locale existe.
          _Line('Référence', transfer.serverId ?? 'En attente du serveur'),
          const _DashedLine(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Frais', style: TextStyle(color: _grey, fontSize: 16)),
              Text(
                formatAmount(0),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const _DashedLine(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatAmount(transfer.amount),
                style: TextStyle(
                  // Comme dans la liste : barré et gris, ce montant n'a pas
                  // quitté le compte.
                  color: unsuccessful ? _grey : AppColors.red,
                  decoration: unsuccessful ? TextDecoration.lineThrough : null,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(label, style: const TextStyle(color: _grey, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Séparateur en pointillés du reçu.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  static const _dash = 6.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < constraints.maxWidth ~/ (_dash + _gap); i++)
            const SizedBox(
              width: _dash,
              height: 1,
              child: ColoredBox(color: AppColors.border),
            ),
        ],
      ),
    ),
  );
}
