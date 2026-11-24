import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/auth_providers.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/send_transfer_page.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

import '../../../auth/auth_fakes.dart';
import '../../domain/fakes.dart';
import '../presentation_fakes.dart';

void main() {
  testWidgets('un double appui sur « Envoyer » ne déclenche qu\'un seul '
      'SendTransfer', (tester) async {
    // L'envoi reste « en vol » tant qu'on ne complète pas ce Completer.
    final inFlight = Completer<Result<Transfer>>();
    final sendTransfer = FakeSendTransfer((_, _) => inFlight.future);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sendTransferProvider.overrideWithValue(sendTransfer),
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
          pinLockProvider.overrideWithValue(FakePinLock()),
          authNotifierProvider.overrideWith(
            () => FixedAuthNotifier(AuthStatus.unlocked),
          ),
        ],
        child: const MaterialApp(home: SendTransferPage()),
      ),
    );
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
}
