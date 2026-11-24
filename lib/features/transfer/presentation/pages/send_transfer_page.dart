import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/pages/pin_pages.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/send_transfer_notifier.dart';

/// Formulaire d'envoi. La validation n'est faite qu'une fois, dans le domaine
/// (SendTransfer) : l'écran affiche ses messages au lieu de la dupliquer.
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

  @override
  void initState() {
    super.initState();
    // Retour sur un formulaire déjà envoyé : on réaffiche son contenu figé.
    final sent = ref.read(sendTransferNotifierProvider).sentRequest;
    if (sent != null) _fill(sent);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    _pin.dispose();
    super.dispose();
  }

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
    ref.read(sendTransferNotifierProvider.notifier).startNew();
    _name.clear();
    _phone.clear();
    _amount.clear();
    _pin.clear();
  }

  void _send() {
    final pin = _pin.text;
    // Le code secret ne reste pas affiché, même masqué.
    _pin.clear();
    ref.read(sendTransferNotifierProvider.notifier).send(_request(), pin: pin);
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(sendTransferNotifierProvider);
    final notifier = ref.read(sendTransferNotifierProvider.notifier);
    final editable = !form.isLocked && !form.isSending;
    final message = _message(form);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau transfert')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            enabled: editable,
            decoration: const InputDecoration(labelText: 'Nom du bénéficiaire'),
          ),
          TextField(
            controller: _phone,
            enabled: editable,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Numéro (10 chiffres)',
            ),
          ),
          TextField(
            controller: _amount,
            enabled: editable,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
          ),
          if (!form.isLocked) ...[
            PinField(
              controller: _pin,
              label: 'Code secret',
              enabled: !form.isSending,
            ),
            if (form.pinError != null) Text(form.pinError!),
            const SizedBox(height: 16),
            FilledButton(
              // null = désactivé pendant l'envoi.
              onPressed: form.isSending ? null : _send,
              child: Text(form.isSending ? 'Envoi en cours…' : 'Envoyer'),
            ),
          ],
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(message),
            ),
          if (form.canRetry)
            OutlinedButton(
              onPressed: form.isSending ? null : notifier.retry,
              child: Text(form.isSending ? 'Envoi en cours…' : 'Réessayer'),
            ),
          if (form.isLocked) ...[
            TextButton(
              onPressed: () => context.go('/transfers/${form.idempotencyKey}'),
              child: const Text('Voir le détail'),
            ),
            TextButton(
              onPressed: form.isSending ? null : _startNew,
              child: const Text('Nouveau transfert'),
            ),
          ],
        ],
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
    Err(failure: RejectedFailure(:final code)) =>
      'Transfert refusé par le serveur ($code).',
    Err(failure: UnauthorizedFailure()) =>
      'Session expirée : reconnectez-vous puis réessayez.',
    Err() => 'Envoi impossible pour le moment.',
  };
}
