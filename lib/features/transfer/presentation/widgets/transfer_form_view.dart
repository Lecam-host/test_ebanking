import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/light_app_bar.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/recent_beneficiaries.dart';

/// Formulaire d'envoi, d'après l'écran « Transfer » du kit, avec nos trois
/// champs (nom, numéro, montant) :
/// - le compte du client et son dernier solde connu ;
/// - le type de transfert (un seul actif dans ce test, les autres grisés) ;
/// - les bénéficiaires récents, tirés de l'historique : un appui remplit le
///   nom et le numéro ;
/// - le montant en lettres sous le champ du montant.
class TransferFormView extends StatelessWidget {
  const TransferFormView({
    super.key,
    required this.name,
    required this.phone,
    required this.amount,
    required this.senderPhone,
    required this.balance,
    required this.beneficiaries,
    required this.message,
    required this.onChanged,
    required this.onContinue,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController amount;
  final String senderPhone;

  /// Dernier solde connu ; null avant la première synchro.
  final int? balance;
  final List<Beneficiary> beneficiaries;

  /// Problèmes de saisie renvoyés par le domaine.
  final String? message;

  /// Un champ a changé : l'écran se redessine (bouton, montant en lettres).
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  bool get _filled =>
      name.text.trim().isNotEmpty &&
      phone.text.isNotEmpty &&
      amount.text.isNotEmpty;

  void _select(Beneficiary beneficiary) {
    name.text = beneficiary.name;
    phone.text = beneficiary.phone;
    onChanged();
  }

  void _clearBeneficiary() {
    name.clear();
    phone.clear();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = int.tryParse(amount.text) ?? 0;
    return Scaffold(
      appBar: lightAppBar('Transfert'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          _AccountBox(senderPhone: senderPhone),
          // Toujours présent, même vide : si la ligne apparaissait à
          // l'arrivée du solde, les éléments suivants se décaleraient et le
          // champ en cours de saisie serait recréé (texte tapé perdu).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
            child: Text(
              balance == null
                  ? ''
                  : 'Solde disponible : ${formatAmount(balance!)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const _SectionTitle('Type de transfert'),
          const _TransferTypes(),
          const _SectionTitle('Bénéficiaire'),
          _Beneficiaries(
            beneficiaries: beneficiaries,
            selectedPhone: phone.text,
            onSelect: _select,
            onNew: _clearBeneficiary,
          ),
          const SizedBox(height: 24),
          _FormCard(
            children: [
              TextField(
                controller: name,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  hintText: 'Nom du bénéficiaire',
                ),
              ),
              TextField(
                controller: phone,
                onChanged: (_) => onChanged(),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: 'Numéro (10 chiffres)',
                  counterText: '',
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amount,
                    onChanged: (_) => onChanged(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Montant (FCFA)',
                    ),
                  ),
                  if (amountValue > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
                      child: Text(
                        amountInWords(amountValue),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (message != null)
                Text(message!, style: const TextStyle(color: AppColors.red)),
              FilledButton(
                // Grisé tant qu'un champ est vide ; les règles précises sont
                // vérifiées par le domaine à l'appui.
                onPressed: _filled ? onContinue : null,
                child: const Text('Continuer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _comingSoon(BuildContext context) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bientôt disponible.')));

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF909090),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Le compte du client : un seul dans ce test, désigné par son numéro masqué.
class _AccountBox extends StatelessWidget {
  const _AccountBox({required this.senderPhone});

  final String senderPhone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      'Mon compte  ${maskPhone(senderPhone)}',
      style: const TextStyle(color: AppColors.text, fontSize: 16),
    ),
  );
}

/// Types de transfert du kit : seul l'envoi par numéro existe dans ce test,
/// les autres restent visibles, grisés, comme les tuiles de l'accueil.
class _TransferTypes extends StatelessWidget {
  const _TransferTypes();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: ListView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      children: [
        const _TypeCard(
          icon: Icons.smartphone,
          label: 'Transfert par numéro',
          active: true,
        ),
        const SizedBox(width: 12),
        _TypeCard(
          icon: Icons.person,
          label: 'Vers la même banque',
          onTap: () => _comingSoon(context),
        ),
        const SizedBox(width: 12),
        _TypeCard(
          icon: Icons.account_balance,
          label: 'Vers une autre banque',
          onTap: () => _comingSoon(context),
        ),
      ],
    ),
  );
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: active ? AppColors.primary : const Color(0xFFDCDCDC),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// « + » (nouveau bénéficiaire), puis les bénéficiaires récents.
class _Beneficiaries extends StatelessWidget {
  const _Beneficiaries({
    required this.beneficiaries,
    required this.selectedPhone,
    required this.onSelect,
    required this.onNew,
  });

  final List<Beneficiary> beneficiaries;
  final String selectedPhone;
  final ValueChanged<Beneficiary> onSelect;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: ListView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      children: [
        _PersonCard(
          tooltip: 'Nouveau bénéficiaire',
          onTap: onNew,
          avatar: const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceTint,
            child: Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
        for (final beneficiary in beneficiaries) ...[
          const SizedBox(width: 12),
          _PersonCard(
            label: beneficiary.name,
            selected: beneficiary.phone == selectedPhone,
            onTap: () => onSelect(beneficiary),
            avatar: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                _initials(beneficiary.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  /// « Awa Kone » → « AK ».
  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
      .join();
}

/// Carte du kit : blanche à ombre douce, indigo quand elle est choisie.
class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.avatar,
    required this.onTap,
    this.label,
    this.tooltip,
    this.selected = false,
  });

  final Widget avatar;
  final VoidCallback onTap;
  final String? label;
  final String? tooltip;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
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
          onTap: onTap,
          child: SizedBox(
            width: 96,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                avatar,
                if (label != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

/// Fond blanc arrondi à ombre douce, comme le bloc du formulaire du kit.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
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
      spacing: 16,
      children: children,
    ),
  );
}
