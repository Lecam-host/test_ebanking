import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/app/router.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/transfer/presentation/auto_resume.dart';

/// Racine de l'application.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Verrouillage après un passage en arrière-plan (voir AuthNotifier).
    final auth = ref.read(authNotifierProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: auth.onHidden,
      onShow: auth.onShown,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Démarre la reprise automatique et la garde active tant que l'app tourne.
    ref.watch(autoResumeProvider);
    return MaterialApp.router(
      title: 'test_ebanking',
      routerConfig: ref.watch(routerProvider),
    );
  }
}
