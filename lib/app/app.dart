import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/app/router.dart';
import 'package:test_ebanking/core/presentation/app_theme.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/push/domain/entities/push_message.dart';
import 'package:test_ebanking/features/push/presentation/push_activation.dart';
import 'package:test_ebanking/features/push/presentation/push_banner.dart';
import 'package:test_ebanking/features/push/presentation/push_providers.dart';
import 'package:test_ebanking/features/transfer/presentation/auto_resume.dart';
import 'package:test_ebanking/features/transfer/presentation/transfer_providers.dart';

/// Racine de l'application.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final AppLifecycleListener _lifecycle;
  final _pushSubscriptions = <StreamSubscription<Object>>[];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authNotifierProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: () {
        auth.onHidden();
        // Un bandeau de notification serait périmé au retour : l'écran
        // affichera de toute façon le statut à jour.
        _messenger.currentState?.clearSnackBars();
      },
      onShow: () {
        // Verrouillage après un passage en arrière-plan (voir AuthNotifier).
        auth.onShown();
        // Retour au premier plan, souvent depuis une notification : les
        // statuts sont rafraîchis tout de suite.
        ref.read(autoResumeProvider).run();
      },
    );

    final push = ref.read(pushMessagingProvider);
    _pushSubscriptions
      ..add(push.openedTransfers.listen(_openTransfer))
      ..add(push.foregroundMessages.listen(_showInApp));
    // L'app a été lancée par l'appui sur une notification.
    push.initialTransfer().then((key) {
      if (key != null) _openTransfer(key);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    for (final subscription in _pushSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  /// Le routeur passe d'abord par le déverrouillage si besoin, puis revient
  /// sur ce transfert.
  void _openTransfer(String transferKey) =>
      ref.read(routerProvider).go('/transfers/$transferKey');

  /// App ouverte : un bandeau dans l'app plutôt qu'une notification système,
  /// et l'historique rafraîchi tout de suite.
  void _showInApp(PushMessage message) {
    ref.read(autoResumeProvider).run();
    final messenger = _messenger.currentState;
    if (messenger == null) return;
    showPushBanner(
      messenger,
      message,
      onOpen: () => _openTransfer(message.transferKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gardés actifs tant que l'app tourne : reprise automatique et
    // inscription aux notifications.
    ref.watch(autoResumeProvider);
    ref.watch(pushActivationProvider);
    // Chaque synchro réussie prouve que le serveur répond : si l'inscription
    // aux notifications avait échoué, elle est refaite à ce moment-là.
    ref.listen(
      historyProvider.select((history) => history.value?.lastSyncedAt),
      (previous, syncedAt) {
        if (syncedAt != null && syncedAt != previous) {
          ref.read(pushSubscriptionProvider).retryIfNeeded();
        }
      },
    );
    return MaterialApp.router(
      title: 'test_ebanking',
      theme: buildAppTheme(),
      scaffoldMessengerKey: _messenger,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
