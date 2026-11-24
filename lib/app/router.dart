import 'package:go_router/go_router.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/history_page.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/send_transfer_page.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/transfer_detail_page.dart';

final appRouter = GoRouter(
  initialLocation: '/transfers',
  routes: [
    GoRoute(
      path: '/send',
      builder: (context, state) => const SendTransferPage(),
    ),
    GoRoute(
      path: '/transfers',
      builder: (context, state) => const HistoryPage(),
      routes: [
        // L'identifiant est la clé d'idempotence, pas l'id serveur : elle
        // existe dès l'enregistrement local, avant toute réponse du serveur.
        GoRoute(
          path: ':id',
          builder: (context, state) =>
              TransferDetailPage(idempotencyKey: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);
