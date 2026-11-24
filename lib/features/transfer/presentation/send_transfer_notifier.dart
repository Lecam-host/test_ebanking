import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
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
  SendFormState build() => _newForm();

  Future<void> send(TransferRequest request) async {
    // Un double appui arrive avant que le bouton soit redessiné désactivé :
    // c'est ici qu'il est arrêté.
    if (state.isSending) return;

    // Formulaire figé : on renvoie toujours le contenu déjà enregistré.
    final toSend = state.sentRequest ?? request;
    final key = state.idempotencyKey;
    state = SendFormState(
      idempotencyKey: key,
      isSending: true,
      sentRequest: state.sentRequest,
      result: state.result,
    );

    try {
      final result = await ref.read(sendTransferProvider)(toSend, key);
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

  /// Même clé, même contenu.
  Future<void> retry() async {
    final sent = state.sentRequest;
    if (sent != null) await send(sent);
  }

  /// Nouveau transfert : nouvelle clé et formulaire vierge. Avec build(),
  /// c'est le seul endroit où une clé est créée.
  void startNew() {
    if (!state.isSending) state = _newForm();
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
