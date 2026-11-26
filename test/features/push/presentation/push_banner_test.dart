import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/push/domain/entities/push_message.dart';
import 'package:test_ebanking/features/push/presentation/push_banner.dart';

const processing = PushMessage(
  transferKey: 'k1',
  title: 'Transfert en cours de traitement',
);
const paid = PushMessage(transferKey: 'k1', title: 'Transfert payé');

void main() {
  Future<ScaffoldMessengerState> pumpMessenger(WidgetTester tester) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(scaffoldMessengerKey: key, home: const Scaffold()),
    );
    return key.currentState!;
  }

  testWidgets('« Voir » ouvre le transfert', (tester) async {
    final messenger = await pumpMessenger(tester);
    String? opened;

    showPushBanner(messenger, processing, onOpen: () => opened = 'k1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir'));

    expect(opened, 'k1');
  });

  testWidgets('le bandeau disparaît seul, malgré son bouton « Voir »', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);

    showPushBanner(messenger, processing, onOpen: () {});
    await tester.pumpAndSettle();
    expect(find.text(processing.title), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(processing.title), findsNothing);
  });

  testWidgets('un statut plus récent remplace le bandeau en cours', (
    tester,
  ) async {
    final messenger = await pumpMessenger(tester);

    showPushBanner(messenger, processing, onOpen: () {});
    await tester.pumpAndSettle();
    showPushBanner(messenger, paid, onOpen: () {});
    await tester.pumpAndSettle();

    expect(find.text(processing.title), findsNothing);
    expect(find.text(paid.title), findsOneWidget);
  });
}
