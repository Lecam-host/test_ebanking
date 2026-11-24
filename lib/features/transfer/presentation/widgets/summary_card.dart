import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';

/// Carte de l'accueil, d'après la carte bancaire du kit : mêmes formes et
/// couleurs, avec le dernier solde connu et le numéro du client masqué.
///
/// Mesures relevées sur la maquette (en points, relatives à la carte).
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.phone,
    required this.balance,
    required this.updated,
  });

  final String phone;

  /// Dernier solde reçu du serveur ; null avant la première synchro.
  final int? balance;

  /// « Mis à jour il y a X min » : hors ligne, le solde peut dater.
  final String updated;

  static const _height = 204.0;
  static const _navy = Color(0xFF1E1672);
  static const _blue = Color(0xFF1573FE);
  static const _lightBlue = Color(0xFF4FB4FF);

  @override
  Widget build(BuildContext context) => SizedBox(
    // + les deux bandes qui dépassent sous la carte (cartes empilées).
    height: _height + 17.5,
    child: Stack(
      children: [
        _band(
          top: _height - 10,
          height: 27.5,
          inset: 33,
          color: AppColors.primaryLight,
        ),
        _band(
          top: _height - 10,
          height: 19.5,
          inset: 20.5,
          color: AppColors.red,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: _blue,
              child: Stack(
                children: [
                  _disc(
                    center: const Offset(317, 34),
                    radius: 93,
                    color: _lightBlue,
                  ),
                  _disc(
                    center: const Offset(51, 149),
                    radius: 172,
                    color: _navy,
                  ),
                  ..._texts(),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _texts() {
    const white = Colors.white;
    return [
      const Positioned(
        left: 20,
        top: 20,
        child: Text('Mon compte', style: TextStyle(color: white, fontSize: 24)),
      ),
      Positioned(
        left: 20,
        top: 56,
        child: Text(
          updated,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
      const Positioned(
        left: 20,
        top: 89,
        child: Text(
          'Solde disponible',
          style: TextStyle(
            color: white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Positioned(
        left: 20,
        top: 121,
        child: Text(
          maskPhone(phone),
          style: const TextStyle(color: white, fontSize: 18, letterSpacing: 1),
        ),
      ),
      Positioned(
        left: 20,
        top: 146,
        child: Text(
          balance == null ? '— FCFA' : formatAmount(balance!),
          style: const TextStyle(
            color: white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // À la place du logo VISA : la devise.
      const Positioned(
        right: 22,
        bottom: 18,
        child: Text(
          'XOF',
          style: TextStyle(
            color: white,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ];
  }

  /// Disque de [radius] centré en [center] (coordonnées de la carte) ; ce qui
  /// dépasse est coupé par les coins arrondis.
  static Widget _disc({
    required Offset center,
    required double radius,
    required Color color,
  }) => Positioned(
    left: center.dx - radius,
    top: center.dy - radius,
    width: radius * 2,
    height: radius * 2,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );

  /// Bande centrée sous la carte, en retrait de [inset] de chaque côté.
  static Widget _band({
    required double top,
    required double height,
    required double inset,
    required Color color,
  }) => Positioned(
    left: inset,
    right: inset,
    top: top,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}
