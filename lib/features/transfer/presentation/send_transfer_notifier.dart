import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_request.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// État du formulaire d'envoi.
class SendFormState {
  const SendFormState({
    required this.idempotencyKey,
    this.isSending = false,
    this.sentRequest,
    this.result,
    this.pinError,
  });

  /// Clé de CE formulaire : la même pour chaque appui et chaque « Réessayer ».
  final String idempotencyKey;

  /// Envoi en cours : le bouton est désactivé.
  final bool isSending;

  /// Contenu déjà enregistré avec cette clé. Dès qu'il existe, le formulaire
  /// est figé : la même clé ne doit jamais repartir avec un autre contenu.
  final TransferRequest? sentRequest;

  /// Résultat du dernier envoi ; null tant que rien n'est revenu.
  final Result<Transfer>? result;

  /// Code secret refusé : rien n'a été envoyé.
  final String? pinError;

  bool get isLocked => sentRequest != null;

  /// « Réessayer » a un sens quand le transfert est incertain, ou quand
  /// l'envoi n'a pas abouti (session expirée, erreur imprévue).
  bool get canRetry =>
      isLocked &&
      switch (result) {
        Ok(:final value) => value.status.needsReconciliation,
        Err(failure: RejectedFailure()) => false,
        _ => true,
      };
}

class SendTransferNotifier extends Notifier<SendFormState> {
  @override
  SendFormState build() {
    // Déconnexion : les données sont effacées, le formulaire repart de zéro.
    ref.listen(authNotifierProvider.select((auth) => auth.status), (_, status) {
      if (status == AuthStatus.signedOut) state = _newForm();
    });
    return _newForm();
  }

  /// Envoi depuis le formulaire : le code secret est demandé à chaque fois,
  /// comme dans les apps de paiement de la région. Un téléphone volé
  /// déverrouillé ne suffit donc pas pour envoyer de l'argent.
  Future<void> send(TransferRequest request, {required String pin}) async {
    // Un double appui arrive avant que le bouton soit redessiné désactivé :
    // c'est ici qu'il est arrêté.
    if (state.isSending) return;
    _setSending();
    if (!await _pinAccepted(pin)) return;
    // Formulaire figé : on renvoie toujours le contenu déjà enregistré.
    await _submit(state.sentRequest ?? request);
  }

  /// « Réessayer » : même clé, même contenu. Le code secret a déjà été donné
  /// pour CE transfert.
  Future<void> retry() async {
    final sent = state.sentRequest;
    if (state.isSending || sent == null) return;
    _setSending();
    await _submit(sent);
  }

  /// Nouveau transfert : nouvelle clé et formulaire vierge. Avec build(),
  /// c'est le seul endroit où une clé est créée.
  void startNew() {
    if (!state.isSending) state = _newForm();
  }

  void _setSending() => state = SendFormState(
    idempotencyKey: state.idempotencyKey,
    isSending: true,
    sentRequest: state.sentRequest,
    result: state.result,
  );

  Future<bool> _pinAccepted(String pin) async {
    final check = await ref.read(pinLockProvider).check(pin);
    if (!ref.mounted) return false;
    switch (check) {
      case PinAccepted():
        return true;
      case PinRejected(:final remainingAttempts):
        state = SendFormState(
          idempotencyKey: state.idempotencyKey,
          sentRequest: state.sentRequest,
          result: state.result,
          pinError:
              'Code secret incorrect. Essais restants : '
              '$remainingAttempts.',
        );
        return false;
      case PinBlocked():
        await ref
            .read(authNotifierProvider.notifier)
            .signOut(message: AuthNotifier.tooManyAttemptsMessage);
        return false;
    }
  }

  Future<void> _submit(TransferRequest toSend) async {
    final key = state.idempotencyKey;
    try {
      final result = await ref.read(sendTransferProvider)(
        toSend,
        key,
        // Client connecté : on n'arrive ici qu'avec une session déverrouillée.
        // Sans numéro, la règle reste vérifiée par le serveur (self_transfer).
        senderPhone: ref.read(currentPhoneProvider) ?? '',
      );
      if (!ref.mounted) return;
      state = SendFormState(
        idempotencyKey: key,
        // Saisie invalide : rien n'a été enregistré, le formulaire reste
        // modifiable (avec la même clé, encore jamais utilisée).
        sentRequest: switch (result) {
          Err(failure: ValidationFailure()) => null,
          _ => toSend,
        },
        result: result,
      );
    } catch (_) {
      // Erreur imprévue (stockage, réponse illisible) : on rend la main. Si le
      // transfert a été enregistré, la reprise le vérifiera ; le formulaire
      // reste figé par prudence.
      if (ref.mounted) {
        state = SendFormState(idempotencyKey: key, sentRequest: toSend);
      }
      rethrow;
    }
  }

  SendFormState _newForm() =>
      SendFormState(idempotencyKey: ref.read(idGeneratorProvider).newId());
}

/// Pas d'autoDispose : quitter l'écran ne doit pas créer une nouvelle clé pour
/// un transfert peut-être déjà parti. Seul « Nouveau transfert » en crée une.
final sendTransferNotifierProvider =
    NotifierProvider<SendTransferNotifier, SendFormState>(
      SendTransferNotifier.new,
    );
