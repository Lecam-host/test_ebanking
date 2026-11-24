import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/pages/login_page.dart';
import 'package:test_ebanking/features/auth/presentation/pages/pin_pages.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/history_page.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/send_transfer_page.dart';
import 'package:test_ebanking/features/transfer/presentation/pages/transfer_detail_page.dart';

const _authPages = {'/start', '/login', '/pin', '/unlock'};

/// Où envoyer l'utilisateur selon l'état de sa session ; null = il reste.
///
/// La page demandée est gardée dans `from` : après le déverrouillage, on y
/// retourne (le formulaire en cours, le transfert ouvert).
String? authRedirect(AuthStatus status, Uri uri) {
  final location = uri.path;
  final onAuthPage = _authPages.contains(location);
  final from = onAuthPage ? uri.queryParameters['from'] : uri.toString();

  final required = switch (status) {
    AuthStatus.restoring => '/start',
    AuthStatus.signedOut => '/login',
    AuthStatus.needsPin => '/pin',
    AuthStatus.locked => '/unlock',
    AuthStatus.unlocked => null,
  };
  if (required == null) return onAuthPage ? (from ?? '/transfers') : null;
  if (location == required) return null;
  return from == null
      ? required
      : Uri(path: required, queryParameters: {'from': from}).toString();
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router relit `redirect` quand ce Listenable change : on le relie à
  // l'état de la session.
  final status = ValueNotifier(ref.read(authNotifierProvider).status);
  ref.listen(authNotifierProvider, (_, next) => status.value = next.status);
  ref.onDispose(status.dispose);

  return GoRouter(
    initialLocation: '/transfers',
    refreshListenable: status,
    redirect: (context, state) => authRedirect(status.value, state.uri),
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/pin', builder: (context, state) => const CreatePinPage()),
      GoRoute(path: '/unlock', builder: (context, state) => const UnlockPage()),
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
});
