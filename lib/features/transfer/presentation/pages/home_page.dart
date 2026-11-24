import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/home_summary.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/widgets/summary_card.dart';

/// Accueil, d'après l'écran « Home » du kit Figma.
///
/// Les neuf tuiles du kit sont gardées pour rester fidèle au design ; seules
/// celles de ce test (Transfert, Historique) sont actives, les autres sont
/// grisées et l'annoncent.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value;
    final transfers = history?.transfers ?? const [];
    final now = ref.watch(nowProvider).value ?? ref.watch(clockProvider).now();
    final phone = ref.watch(currentPhoneProvider) ?? '';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(phone: phone, uncertain: uncertainCount(transfers)),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    SummaryCard(
                      phone: phone,
                      balance: history?.balance,
                      updated: updatedAgo(history?.lastSyncedAt, now),
                    ),
                    const SizedBox(height: 30),
                    GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Laisse déborder l'ombre des tuiles du bord.
                      clipBehavior: Clip.none,
                      children: [
                        _Tile('account', 'Compte et carte'),
                        _Tile(
                          'transfer',
                          'Transfert',
                          onTap: () => context.push('/send'),
                        ),
                        _Tile('withdraw', 'Retrait'),
                        _Tile('mobile_prepaid', 'Recharge mobile'),
                        _Tile('pay_bill', 'Payer une facture'),
                        _Tile('savings', 'Épargne'),
                        _Tile('credit_card', 'Carte de crédit'),
                        _Tile(
                          'history',
                          'Historique',
                          onTap: () => context.go('/transfers'),
                        ),
                        _Tile('beneficiaries', 'Bénéficiaires'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.phone, required this.uncertain});

  final String phone;
  final int uncertain;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 16, 24),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.person, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            'Bonjour, ${formatPhone(phone)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Transferts en vérification',
          onPressed: () => context.go('/transfers'),
          icon: Badge(
            // Pastille : transferts encore « en vérification ».
            isLabelVisible: uncertain > 0,
            label: Text('$uncertain'),
            backgroundColor: AppColors.red,
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, {this.onTap});

  final String icon;
  final String label;

  /// null : service hors du périmètre de ce test.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Opacity(
      opacity: available ? 1 : 0.4,
      child: DecoratedBox(
        // Ombre grise diffuse, plus marquée vers le bas : environ 4 % de noir
        // au bord de la tuile, mesuré sur la maquette.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: onTap ?? () => _comingSoon(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/$icon.svg',
                  width: 28,
                  height: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFF909090),
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bientôt disponible.')));
}
