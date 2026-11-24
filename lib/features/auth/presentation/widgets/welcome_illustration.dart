import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';

/// Illustration de l'écran d'accueil du kit (téléphone dans un cercle, points
/// de couleur), dessinée avec des widgets : pas d'image à embarquer.
/// Positions relevées sur la maquette, relatives au centre du cercle.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 190,
    child: Stack(
      alignment: Alignment.center,
      children: [
        _circle(150, AppColors.surfaceTint),
        _phone(),
        _dot(const Offset(-33, -85), 10, AppColors.primary),
        _dot(const Offset(90, -55), 25, AppColors.red),
        _dot(const Offset(-105, -20), 10, AppColors.green),
        _dot(const Offset(-58, 46), 20, AppColors.orange),
        _dot(const Offset(73, 46), 10, AppColors.blue),
      ],
    ),
  );

  static Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  static Widget _dot(Offset offset, double size, Color color) =>
      Transform.translate(offset: offset, child: _circle(size, color));

  static Widget _phone() => Container(
    width: 49,
    height: 91,
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: const Icon(
      Icons.lock_person_outlined,
      color: Colors.white,
      size: 26,
    ),
  );
}
