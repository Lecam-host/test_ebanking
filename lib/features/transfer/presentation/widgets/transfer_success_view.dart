import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/light_app_bar.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';

/// Confirmation après un envoi accepté, d'après l'écran « Confirm » du kit
/// (illustration n° 4 du kit, embarquée dans l'app).
///
/// Le titre dit « envoyé » et non « payé » : le serveur a accepté le
/// transfert, le paiement suit, et le client est prévenu à chaque étape.
class TransferSuccessView extends StatelessWidget {
  const TransferSuccessView({
    super.key,
    required this.transfer,
    required this.onDone,
  });

  final Transfer transfer;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: lightAppBar('Confirmation'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Image.asset(
          'assets/images/transfer_success.png',
          // Décorative : le texte dessous dit déjà tout.
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 48),
        const Text(
          'Transfert envoyé !',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Vous avez envoyé\n',
            children: [
              TextSpan(
                text: formatAmount(transfer.amount),
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' à '),
              TextSpan(
                text: transfer.recipientName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Espace insécable : le « ! » ne part jamais seul à la ligne.
              const TextSpan(text: ' !'),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vous serez prévenu à chaque étape du traitement.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF909090), fontSize: 13),
        ),
        const SizedBox(height: 40),
        FilledButton(onPressed: onDone, child: const Text('Terminer')),
      ],
    ),
  );
}
