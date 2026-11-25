import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/send_transfer_page.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

import '../../../auth/auth_fakes.dart';
import '../../domain/fakes.dart';
import '../presentation_fakes.dart';

void main() {
  late FakePinLock pinLock;

  Future<void> pumpPage(
    WidgetTester tester,
    FakeSendTransfer sendTransfer, {
    FakeBiometricAuth? biometrics,
    List<Transfer> history = const [],
  }) {
    // Écran haut : tout le récapitulatif est visible sans défiler.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    pinLock = FakePinLock();
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sendTransferProvider.overrideWithValue(sendTransfer),
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
          pinLockProvider.overrideWithValue(pinLock),
          biometricAuthProvider.overrideWithValue(
            biometrics ?? FakeBiometricAuth(available: false),
          ),
          authNotifierProvider.overrideWith(
            () => FixedAuthNotifier(AuthStatus.unlocked),
          ),
          currentPhoneProvider.overrideWithValue('0700000001'),
          historyProvider.overrideWith(
            (ref) => Stream.value(
              TransferHistory(
                transfers: history,
                lastSyncedAt: t0,
                balance: 1000000,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: SendTransferPage()),
      ),
    );
  }

  /// Remplit le formulaire et passe au récapitulatif.
  Future<void> fillAndContinue(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du bénéficiaire'),
      'Awa Kone',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Numéro (10 chiffres)'),
      '0701020304',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Montant (FCFA)'),
      '25000',
    );
    // « Continuer » ne s'active qu'une fois l'écran redessiné, champs remplis.
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuer'));
    await tester.pumpAndSettle();
  }

  Finder confirmButton() => find.widgetWithText(FilledButton, 'Confirmer');

  testWidgets('un double appui sur « Confirmer » ne déclenche qu\'un seul '
      'SendTransfer', (tester) async {
    // L'envoi reste « en vol » tant qu'on ne complète pas ce Completer.
    final inFlight = Completer<Result<Transfer>>();
    final sendTransfer = FakeSendTransfer((_, _) => inFlight.future);
    await pumpPage(tester, sendTransfer);
    await tester.pump(); // l'historique (et son solde) arrive
    // Le dernier solde connu est rappelé sous le montant.
    expect(find.textContaining('Solde disponible'), findsOneWidget);
    await fillAndContinue(tester);

    // Sans empreinte sur le téléphone : le code secret directement.
    await tester.enterText(
      find.widgetWithText(TextField, 'Code secret'),
      '1234',
    );
    await tester.pump();

    // Deux appuis avant que l'écran ait eu le temps de se redessiner.
    await tester.tap(confirmButton());
    await tester.tap(confirmButton());
    await tester.pump();

    // Pendant l'envoi, le bouton est désactivé.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    inFlight.complete(Ok(localTransfer('key-1', TransferStatus.submitted)));
    await tester.pumpAndSettle();

    expect(sendTransfer.keys, ['key-1']);
  });

  testWidgets('récapitulatif, puis empreinte reconnue → « Confirmer » envoie '
      'sans code secret', (tester) async {
    final sendTransfer = FakeSendTransfer();
    await pumpPage(tester, sendTransfer, biometrics: FakeBiometricAuth());
    await fillAndContinue(tester);

    expect(find.text('07 •• •• 00 01'), findsOneWidget); // « De » : le client
    expect(find.text('Awa Kone'), findsOneWidget);
    // Pas encore vérifié : « Confirmer » est désactivé.
    expect(tester.widget<FilledButton>(confirmButton()).onPressed, isNull);

    await tester.tap(find.byTooltip('Vérifier mon empreinte'));
    await tester.pumpAndSettle();
    expect(find.text('Empreinte reconnue'), findsOneWidget);

    await tester.tap(confirmButton());
    await tester.pumpAndSettle();

    expect(sendTransfer.keys, ['key-1']);
    expect(pinLock.checked, isEmpty);
  });

  testWidgets('empreinte refusée → le code secret prend le relais', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeSendTransfer(),
      biometrics: FakeBiometricAuth(recognized: false),
    );
    await fillAndContinue(tester);

    await tester.tap(find.byTooltip('Vérifier mon empreinte'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Code secret'), findsOneWidget);
    expect(tester.widget<FilledButton>(confirmButton()).onPressed, isNull);
  });

  testWidgets('envoi accepté → écran de confirmation ; « Terminer » repart '
      'd\'un formulaire neuf', (tester) async {
    final sendTransfer = FakeSendTransfer(); // répond « envoyé »
    await pumpPage(tester, sendTransfer);
    await fillAndContinue(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Code secret'),
      '1234',
    );
    await tester.pump();

    await tester.tap(confirmButton());
    await tester.pumpAndSettle();

    expect(find.text('Transfert envoyé !'), findsOneWidget);
    expect(find.textContaining('Awa Kone'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Terminer'));
    await tester.pumpAndSettle();

    // Pas d'écran précédent dans ce test : le formulaire repart à zéro.
    expect(find.widgetWithText(FilledButton, 'Continuer'), findsOneWidget);
    expect(find.text('Awa Kone'), findsNothing);
  });

  testWidgets('« Continuer » grisé tant qu\'un champ est vide ; montant '
      'rappelé en lettres', (tester) async {
    await pumpPage(tester, FakeSendTransfer());
    FilledButton continueButton() =>
        tester.widget(find.widgetWithText(FilledButton, 'Continuer'));
    expect(continueButton().onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextField, 'Montant (FCFA)'),
      '25000',
    );
    await tester.pump();

    expect(find.text('vingt-cinq mille francs CFA'), findsOneWidget);
    expect(continueButton().onPressed, isNull); // nom et numéro manquent
  });

  testWidgets('un bénéficiaire récent remplit le nom et le numéro', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeSendTransfer(),
      history: [localTransfer('k1', TransferStatus.paid)], // vers Awa Kone
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Awa Kone'));
    await tester.pump();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.map((field) => field.controller?.text).take(2), [
      'Awa Kone',
      '0701020304',
    ]);
  });
}
