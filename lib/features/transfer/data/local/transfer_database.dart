import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_ebanking/features/transfer/data/local/database_key.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

part 'transfer_database.g.dart';

/// Une seule table sert d'outbox et de cache de l'historique : un transfert
/// reste le même objet, qu'il soit en attente ou confirmé ; seul son statut
/// change. La clé primaire est la clé d'idempotence, donc une réécriture
/// remplace la ligne au lieu de créer un doublon.
@DataClassName('TransferRow')
class Transfers extends Table {
  TextColumn get idempotencyKey => text()();
  TextColumn get serverId => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  TextColumn get recipientName => text()();
  TextColumn get recipientPhone => text()();

  /// Stocké par son nom (« unknownOutcome ») : lisible, et insensible à
  /// l'ordre des valeurs de l'enum.
  TextColumn get status => textEnum<TransferStatus>()();

  /// Dates en secondes Unix (choix par défaut de Drift) : le tri est
  /// numérique, sans piège de fuseau horaire.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {idempotencyKey};
}

/// Table à une seule ligne : l'heure de la dernière synchronisation réussie.
@DataClassName('SyncStateRow')
class SyncState extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Transfers, SyncState])
class TransferDatabase extends _$TransferDatabase {
  /// En test, on passe `NativeDatabase.memory()` : base en mémoire, en clair.
  TransferDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

/// Ouvre la base chiffrée du téléphone.
Future<TransferDatabase> openTransferDatabase() async {
  // Dossier interne de l'app : contrairement à « Documents », il n'est pas
  // visible par l'utilisateur.
  final directory = await getApplicationSupportDirectory();
  final key = await DatabaseKey(const FlutterSecureStorage()).loadOrCreate();
  return TransferDatabase(
    encryptedExecutor(File('${directory.path}/transfers.sqlite'), key),
  );
}

/// Connexion SQLCipher, dans un isolate séparé pour ne pas bloquer l'UI.
/// Fonction à part : la fonction `setup` est envoyée à cet isolate, elle ne
/// doit donc capturer que [hexKey].
QueryExecutor encryptedExecutor(File file, String hexKey) {
  return NativeDatabase.createInBackground(
    file,
    setup: (database) {
      // Clé brute (x'...') : 32 octets aléatoires n'ont pas besoin de la
      // dérivation lente (PBKDF2) prévue pour les mots de passe, ce qui
      // accélère l'ouverture sur un téléphone modeste.
      database.execute("PRAGMA key = \"x'$hexKey'\";");
      // Garde-fou en debug : on tourne bien sur SQLCipher, pas sur un
      // SQLite qui ignorerait la clé et écrirait en clair.
      assert(database.select('PRAGMA cipher_version;').isNotEmpty);
    },
  );
}
