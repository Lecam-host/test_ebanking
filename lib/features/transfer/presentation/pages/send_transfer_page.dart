import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/light_app_bar.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/auth/presentation/pages/pin_pages.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/recent_beneficiaries.dart';
import 'package:test_ebanking/features/transfer/presentation/send_transfer_notifier.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/widgets/transfer_form_view.dart';
import 'package:test_ebanking/features/transfer/presentation/widgets/transfer_success_view.dart';

/// Ouvre l'écran d'envoi (accueil, historique). Après un transfert accepté,
/// il repart d'un formulaire neuf (voir [SendTransferNotifier.open]).
void openSendTransfer(BuildContext context, WidgetRef ref) {
  ref.read(sendTransferNotifierProvider.notifier).open();
  context.push('/send');
}

/// Parcours d'envoi, en trois vues sur la même route :
/// 1. le formulaire (« Continuer » vérifie la saisie dans le domaine) ;
/// 2. le récapitulatif « Confirm » du kit, vérifié par empreinte ou code
///    secret ;
/// 3. la confirmation « Transfert envoyé », une fois le serveur d'accord.
///
/// La validation n'est écrite qu'une fois, dans le domaine : l'écran affiche
/// ses messages au lieu de la dupliquer.
class SendTransferPage extends ConsumerStatefulWidget {
  const SendTransferPage({super.key});

  @override
  ConsumerState<SendTransferPage> createState() => _SendTransferPageState();
}

class _SendTransferPageState extends ConsumerState<SendTransferPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _pin = TextEditingController();

  /// Code secret à la place de l'empreinte : empreinte refusée ou annulée,
  /// ou choix du client.
  var _usePin = false;

  @override
  void initState() {
    super.initState();
    // Retour sur un transfert en cours : on réaffiche son contenu.
    final shown = ref.read(sendTransferNotifierProvider).reviewed;
    if (shown != null) _fill(shown);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    _pin.dispose();
    super.dispose();
  }

  SendTransferNotifier get _notifier =>
      ref.read(sendTransferNotifierProvider.notifier);

  void _fill(TransferRequest request) {
    _name.text = request.recipientName;
    _phone.text = request.recipientPhone;
    _amount.text = request.amount.toString();
  }

  TransferRequest _request() => TransferRequest(
    // Vide ou illisible : 0, que le domaine refusera avec un message clair.
    amount: int.tryParse(_amount.text) ?? 0,
    recipientName: _name.text,
    recipientPhone: _phone.text,
  );

  void _startNew() {
    _notifier.startNew();
    _name.clear();
    _phone.clear();
    _amount.clear();
    _pin.clear();
    setState(() => _usePin = false);
  }

  Future<void> _verifyFingerprint(TransferRequest request) async {
    final recognized = await _notifier.verifyWithBiometrics(
      'Confirmez l\'envoi de ${formatAmount(request.amount)} '
      'à ${request.recipientName}',
    );
    if (!recognized && mounted) setState(() => _usePin = true);
  }

  void _confirm({required bool verified}) {
    final pin = verified ? null : _pin.text;
    // Le code secret ne reste pas affiché, même masqué.
    _pin.clear();
    _notifier.confirm(pin: pin);
  }

  /// « Terminer » : retour à l'écran précédent ; la prochaine ouverture
  /// repartira d'un formulaire neuf. Sans écran précédent (lien direct), on
  /// repart tout de suite d'un formulaire neuf.
  Future<void> _finish() async {
    final popped = await Navigator.of(context).maybePop();
    if (!popped && mounted) _startNew();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(sendTransferNotifierProvider);
    // Demandé dès le formulaire : la réponse est prête au récapitulatif.
    final canUseFingerprint =
        ref.watch(biometricAvailableProvider).value ?? false;

    final accepted = form.accepted;
    if (accepted != null) {
      return TransferSuccessView(transfer: accepted, onDone: _finish);
    }
    final reviewed = form.reviewed;
    if (reviewed != null) return _review(form, reviewed, canUseFingerprint);
    return _form(form);
  }

  Widget _form(SendFormState form) {
    final history = ref.watch(historyProvider).value;
    return TransferFormView(
      name: _name,
      phone: _phone,
      amount: _amount,
      senderPhone: ref.watch(currentPhoneProvider) ?? '',
      // Dernier solde connu, pour information : le serveur vérifie le vrai.
      balance: history?.balance,
      beneficiaries: recentBeneficiaries(history?.transfers ?? const []),
      message: _message(form),
      onChanged: () => setState(() {}),
      onContinue: () => _notifier.review(_request()),
    );
  }

  /// Récapitulatif « Confirm » du kit, puis suivi tant que le transfert
  /// n'est pas confirmé par le serveur.
  Widget _review(
    SendFormState form,
    TransferRequest request,
    bool canUseFingerprint,
  ) {
    final message = _message(form);
    final askPin = !canUseFingerprint || _usePin;
    final canConfirm =
        !form.isSending && (form.verified || (askPin && _pin.text.length == 4));
    final phone = ref.watch(currentPhoneProvider) ?? '';

    return PopScope(
      // Avant l'envoi, « retour » ramène au formulaire au lieu de quitter.
      canPop: form.isLocked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _notifier.editDraft();
      },
      child: Scaffold(
        appBar: lightAppBar('Confirmation'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const _SectionLabel('Vérifiez les informations du transfert'),
            _ReadOnlyField('De', maskPhone(phone)),
            _ReadOnlyField('À', request.recipientName),
            _ReadOnlyField(
              'Numéro du bénéficiaire',
              formatPhone(request.recipientPhone),
            ),
            // Le serveur simulé ne prend aucun frais.
            _ReadOnlyField('Frais', formatAmount(0)),
            _ReadOnlyField('Montant', formatAmount(request.amount)),
            if (!form.isLocked) ...[
              _SectionLabel(
                askPin
                    ? 'Confirmez avec votre code secret'
                    : 'Confirmez avec votre empreinte',
              ),
              if (askPin)
                PinField(
                  controller: _pin,
                  label: 'Code secret',
                  enabled: !form.isSending,
                  // Le bouton s'active au 4e chiffre.
                  onChanged: (_) => setState(() {}),
                )
              else ...[
                _Fingerprint(
                  recognized: form.verified,
                  onTap: form.isSending || form.verified
                      ? null
                      : () => _verifyFingerprint(request),
                ),
                if (!form.verified)
                  TextButton(
                    onPressed: () => setState(() => _usePin = true),
                    child: const Text('Utiliser le code secret'),
                  ),
              ],
              if (form.pinError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    form.pinError!,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                // null = désactivé : pas encore vérifié, ou envoi en cours.
                onPressed: canConfirm
                    ? () => _confirm(verified: form.verified)
                    : null,
                child: Text(form.isSending ? 'Envoi en cours…' : 'Confirmer'),
              ),
            ],
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(message),
              ),
            if (form.canRetry)
              OutlinedButton(
                onPressed: form.isSending ? null : _notifier.retry,
                child: Text(form.isSending ? 'Envoi en cours…' : 'Réessayer'),
              ),
            if (form.isLocked) ...[
              TextButton(
                onPressed: () =>
                    context.go('/transfers/${form.idempotencyKey}'),
                child: const Text('Voir le détail'),
              ),
              TextButton(
                onPressed: form.isSending ? null : _startNew,
                child: const Text('Nouveau transfert'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _message(SendFormState form) => switch (form.result) {
    null when form.isLocked =>
      'Erreur inattendue : le transfert sera vérifié automatiquement.',
    null => null,
    Ok(:final value) when value.status.needsReconciliation =>
      'Vérification en cours : le serveur n\'a pas encore confirmé. '
          'L\'app vérifie toute seule ; rien ne partira deux fois.',
    Ok(:final value) => 'Transfert ${statusLabel(value.status).toLowerCase()}.',
    Err(failure: ValidationFailure(:final errors)) => errors.join('\n'),
    Err(failure: RejectedFailure(code: 'insufficient_funds')) =>
      'Solde insuffisant : transfert refusé, rien n\'a été débité.',
    Err(failure: RejectedFailure(code: 'self_transfer')) =>
      'Vous ne pouvez pas vous envoyer de l\'argent.',
    Err(failure: RejectedFailure(:final code)) =>
      'Transfert refusé par le serveur ($code).',
    Err(failure: UnauthorizedFailure()) =>
      'Session expirée : reconnectez-vous puis réessayez.',
    Err() => 'Envoi impossible pour le moment.',
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12),
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

/// Ligne du récapitulatif : libellé gris, valeur dans un cadre arrondi.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF909090),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            value,
            style: const TextStyle(color: AppColors.text, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

/// Empreinte du kit : lavande tant qu'elle n'est pas vérifiée, indigo une
/// fois reconnue.
class _Fingerprint extends StatelessWidget {
  const _Fingerprint({required this.recognized, required this.onTap});

  final bool recognized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IconButton(
        tooltip: 'Vérifier mon empreinte',
        iconSize: 80,
        onPressed: onTap,
        icon: Icon(
          Icons.fingerprint,
          color: recognized
              ? AppColors.primary
              : AppColors.primaryLight.withValues(alpha: 0.55),
        ),
      ),
      Text(
        recognized ? 'Empreinte reconnue' : 'Touchez pour vérifier',
        style: const TextStyle(color: Color(0xFF909090), fontSize: 13),
      ),
    ],
  );
}
