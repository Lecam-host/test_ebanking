import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'features/transfer/data/local/transfer_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La base est ouverte avant le premier écran : l'historique doit s'afficher
  // tout de suite, même sans réseau.
  final database = await openTransferDatabase();
  runApp(ProviderScope(overrides: appOverrides(database), child: const App()));
}
