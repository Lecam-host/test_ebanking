import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/app/router.dart';
import 'package:test_ebanking/features/transfer/presentation/auto_resume.dart';

/// Racine de l'application.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Démarre la reprise automatique et la garde active tant que l'app tourne.
    ref.watch(autoResumeProvider);
    return MaterialApp.router(title: 'test_ebanking', routerConfig: appRouter);
  }
}
