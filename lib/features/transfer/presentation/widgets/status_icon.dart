import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

/// Pastille de couleur d'un statut, comme les icônes de l'écran
/// « Transaction report » du kit. Couleurs de la palette du kit : orange en
/// vérification, bleu puis indigo en route, vert payé, rouge échoué ou refusé.
///
/// La couleur n'est qu'un repère : le statut est toujours écrit à côté.
class StatusIcon extends StatelessWidget {
  const StatusIcon(this.status, {super.key, this.size = 48});

  final TransferStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TransferStatus.pendingSubmission || TransferStatus.unknownOutcome => (
        AppColors.orange,
        Icons.hourglass_top_rounded,
      ),
      TransferStatus.submitted => (AppColors.blue, Icons.north_east_rounded),
      TransferStatus.processing => (AppColors.primary, Icons.sync_rounded),
      TransferStatus.paid => (AppColors.green, Icons.check_rounded),
      TransferStatus.failed => (AppColors.red, Icons.close_rounded),
      TransferStatus.rejected => (AppColors.red, Icons.block_rounded),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(icon, color: Colors.white, size: size / 2),
    );
  }
}
