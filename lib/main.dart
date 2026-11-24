import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'features/transfer/data/local/transfer_database.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Configuration générée par FlutterFire (clés client du projet Firebase de
  // démo : publiques par nature, la sécurité est côté serveur).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // La base est ouverte avant le premier écran : l'historique doit s'afficher
  // tout de suite, même sans réseau.
  final database = await openTransferDatabase();
  runApp(ProviderScope(overrides: appOverrides(database), child: const App()));
}
