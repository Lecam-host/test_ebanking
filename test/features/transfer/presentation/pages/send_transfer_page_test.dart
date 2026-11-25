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
  Future<void> pumpPage(WidgetTester tester, FakeSendTransfer sendTransfer) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            sendTransferProvider.overrideWithValue(sendTransfer),
            idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
            pinLockProvider.overrideWithValue(FakePinLock()),
            authNotifierProvider.overrideWith(
              () => FixedAuthNotifier(AuthStatus.unlocked),
            ),
            currentPhoneProvider.overrideWithValue('0700000001'),
            historyProvider.overrideWith(
              (ref) => Stream.value(
                TransferHistory(
                  transfers: const [],
                  lastSyncedAt: t0,
                  balance: 1000000,
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: SendTransferPage()),
        ),
      );

  Future<void> fillForm(WidgetTester tester) async {
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
    await tester.enterText(
      find.widgetWithText(TextField, 'Code secret'),
      '1234',
    );
  }

  testWidgets('un double appui sur « Envoyer » ne déclenche qu\'un seul '
      'SendTransfer', (tester) async {
    // L'envoi reste « en vol » tant qu'on ne complète pas ce Completer.
    final inFlight = Completer<Result<Transfer>>();
    final sendTransfer = FakeSendTransfer((_, _) => inFlight.future);
    await pumpPage(tester, sendTransfer);
    await tester.pump(); // l'historique (et son solde) arrive
    // Le dernier solde connu est rappelé sous le montant.
    expect(find.textContaining('Solde disponible'), findsOneWidget);
    await fillForm(tester);

    // Deux appuis avant que l'écran ait eu le temps de se redessiner.
    final sendButton = find.widgetWithText(FilledButton, 'Envoyer');
    await tester.tap(sendButton);
    await tester.tap(sendButton);
    await tester.pump();

    // Pendant l'envoi, le bouton est désactivé.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    inFlight.complete(Ok(localTransfer('key-1', TransferStatus.submitted)));
    await tester.pumpAndSettle();

    expect(sendTransfer.keys, ['key-1']);
  });

  testWidgets('envoi accepté → écran de confirmation ; « Terminer » repart '
      'd\'un formulaire neuf', (tester) async {
    final sendTransfer = FakeSendTransfer(); // répond « envoyé »
    await pumpPage(tester, sendTransfer);
    await fillForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text('Transfert envoyé !'), findsOneWidget);
    expect(find.textContaining('Awa Kone'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Terminer'));
    await tester.pumpAndSettle();

    // Pas d'écran précédent dans ce test : le formulaire repart à zéro.
    expect(find.widgetWithText(FilledButton, 'Envoyer'), findsOneWidget);
    expect(find.text('Awa Kone'), findsNothing);
  });
}
