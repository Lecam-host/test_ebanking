import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_history.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';
import 'package:test_ebanking/features/transfer/presentation/formatters.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/history_page.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/transfer_detail_page.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

import '../../domain/fakes.dart';

final now = DateTime(2026, 11, 23, 18);

Transfer transferAt(
  String key,
  TransferStatus status,
  DateTime at, {
  String name = 'Awa Kone',
  String? serverId,
}) => Transfer(
  idempotencyKey: key,
  serverId: serverId,
  amount: 25000,
  currency: 'XOF',
  recipientName: name,
  recipientPhone: '0701020304',
  status: status,
  createdAt: at,
  updatedAt: at,
);

final history = [
  transferAt(
    'k1',
    TransferStatus.paid,
    DateTime(2026, 11, 23, 10),
    serverId: 'tr_1',
  ),
  transferAt(
    'k2',
    TransferStatus.unknownOutcome,
    DateTime(2026, 11, 23, 9),
    name: 'Jean Yao',
  ),
  transferAt(
    'k3',
    TransferStatus.failed,
    DateTime(2026, 11, 22, 20),
    name: 'Fatou Diallo',
    serverId: 'tr_3',
  ),
];

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    List<Transfer> transfers = const [],
    String location = '/transfers',
    bool online = true,
    DateTime? lastSyncedAt,
    Failure? syncFailure,
    List<String>? log,
  }) {
    log ??= [];
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/transfers',
          builder: (context, state) => const HistoryPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => TransferDetailPage(
                idempotencyKey: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyProvider.overrideWith(
            (ref) => Stream.value(
              TransferHistory(
                transfers: transfers,
                lastSyncedAt: lastSyncedAt ?? now,
                balance: 975000,
              ),
            ),
          ),
          // Lus seulement par « tirer pour rafraîchir ».
          transferRepositoryProvider.overrideWithValue(
            FakeTransferRepository(log)..historyFailure = syncFailure,
          ),
          transferLocalStoreProvider.overrideWithValue(
            FakeTransferLocalStore(log),
          ),
          isOnlineProvider.overrideWith((ref) => Stream.value(online)),
          nowProvider.overrideWith((ref) => Stream.value(now)),
          currentPhoneProvider.overrideWithValue('0700000001'),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('regroupé par jour ; les onglets filtrent ; un échec est '
      'barré', (tester) async {
    await pumpApp(tester, transfers: history);
    await tester.pumpAndSettle();

    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.text('Hier'), findsOneWidget);
    expect(find.text('Payé'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);

    await tester.tap(find.text('Échoués'));
    await tester.pump();
    expect(find.text('Fatou Diallo'), findsOneWidget);
    expect(find.text('Awa Kone'), findsNothing);
    expect(find.text('Aujourd\'hui'), findsNothing);
    // Remboursé : le montant est barré.
    final amount = tester.widget<Text>(find.text(formatAmount(25000)));
    expect(amount.style?.decoration, TextDecoration.lineThrough);

    // « En cours » garde les transferts en vérification.
    await tester.tap(find.text('En cours'));
    await tester.pump();
    expect(find.text('Jean Yao'), findsOneWidget);
    expect(find.text('Fatou Diallo'), findsNothing);

    await tester.tap(find.text('Payés'));
    await tester.pump();
    expect(find.text('Awa Kone'), findsOneWidget);
    expect(find.text('Jean Yao'), findsNothing);
  });

  testWidgets('hors ligne : bandeau, heure de mise à jour, liste vide', (
    tester,
  ) async {
    await pumpApp(
      tester,
      online: false,
      lastSyncedAt: now.subtract(const Duration(minutes: 5)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hors connexion'), findsOneWidget);
    expect(find.text('Mis à jour il y a 5 min'), findsOneWidget);
    expect(find.text('Aucun transfert pour l\'instant'), findsOneWidget);
  });

  testWidgets('un appui ouvre le reçu du transfert', (tester) async {
    await pumpApp(tester, transfers: history);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Awa Kone'));
    await tester.pumpAndSettle();

    expect(find.text('Détail du transfert'), findsOneWidget);
    expect(find.text('Payé'), findsOneWidget);
    expect(find.text(statusExplanation(TransferStatus.paid)), findsOneWidget);
    expect(find.text('07 •• •• 00 01'), findsOneWidget); // « De » : le client
    expect(find.text('07 01 02 03 04'), findsOneWidget);
    expect(find.text('tr_1'), findsOneWidget);
  });

  testWidgets('transfert incertain : rassure et attend la référence', (
    tester,
  ) async {
    await pumpApp(tester, transfers: history, location: '/transfers/k2');
    await tester.pumpAndSettle();

    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(
      find.textContaining('il ne partira jamais deux fois'),
      findsOneWidget,
    );
    expect(find.text('En attente du serveur'), findsOneWidget);
  });

  testWidgets('clé inconnue : « Transfert introuvable »', (tester) async {
    await pumpApp(tester, transfers: history, location: '/transfers/nope');
    await tester.pumpAndSettle();

    expect(find.text('Transfert introuvable'), findsOneWidget);
  });

  // Il faut tirer plus du quart de la hauteur (2000) pour rafraîchir.
  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
  }

  testWidgets('rafraîchir sans réseau : « Serveur injoignable »', (
    tester,
  ) async {
    final log = <String>[];
    await pumpApp(
      tester,
      transfers: history,
      syncFailure: const NetworkFailure(),
      log: log,
    );
    await tester.pumpAndSettle();

    await pullToRefresh(tester);

    expect(log, ['api.fetchHistory']);
    expect(
      find.text('Serveur injoignable : historique enregistré affiché.'),
      findsOneWidget,
    );
  });

  testWidgets('rafraîchir après une révocation : pas de « Serveur '
      'injoignable », la connexion en donne la raison', (tester) async {
    final log = <String>[];
    await pumpApp(
      tester,
      transfers: history,
      syncFailure: const UnauthorizedFailure(),
      log: log,
    );
    await tester.pumpAndSettle();

    await pullToRefresh(tester);

    expect(log, ['api.fetchHistory']);
    expect(find.byType(SnackBar), findsNothing);
  });
}
