import 'package:flutter/material.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';

/// Mise en page du kit : en-tête indigo, puis une feuille blanche aux coins
/// supérieurs arrondis, avec un titre d'accueil.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.children,
  });

  /// Titre de l'en-tête (« Connexion »).
  final String title;

  /// Grand titre indigo de la feuille (« Bienvenue, »).
  final String headline;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    appBar: AppBar(title: Text(title)),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Text(
              headline,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}
