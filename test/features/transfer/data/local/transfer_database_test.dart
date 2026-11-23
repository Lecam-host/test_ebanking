import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/features/transfer/data/local/transfer_database.dart';
import 'package:test_ebanking/features/transfer/data/transfer_local_store_impl.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer.dart';
import 'package:test_ebanking/features/transfer/domain/entities/transfer_status.dart';

void main() {
  test('la base est chiffrée : illisible sans la clé, relue avec', () async {
    final directory = await Directory.systemTemp.createTemp('transfer_db_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/transfers.sqlite');
    final key = 'ab' * 32; // 32 octets en hexadécimal

    final encrypted = TransferDatabase(encryptedExecutor(file, key));
    await TransferLocalStoreImpl(encrypted).save(
      Transfer(
        idempotencyKey: 'k1',
        amount: 25000,
        currency: 'XOF',
        recipientName: 'Awa Kone',
        recipientPhone: '0701020304',
        status: TransferStatus.pendingSubmission,
        createdAt: DateTime(2026, 11, 23, 10),
        updatedAt: DateTime(2026, 11, 23, 10),
      ),
    );
    await encrypted.close();

    // Le nom du bénéficiaire n'apparaît nulle part en clair dans le fichier.
    final rawContent = String.fromCharCodes(await file.readAsBytes());
    expect(rawContent, isNot(contains('Awa Kone')));

    // Sans la clé, SQLite ne reconnaît même pas le fichier.
    final withoutKey = TransferDatabase(NativeDatabase(file));
    await expectLater(
      withoutKey.select(withoutKey.transfers).get(),
      throwsA(anything),
    );
    await withoutKey.close();

    // Avec la clé, on retrouve le transfert.
    final reopened = TransferDatabase(encryptedExecutor(file, key));
    final saved = await TransferLocalStoreImpl(reopened).findByKey('k1');
    expect(saved?.recipientName, 'Awa Kone');
    await reopened.close();
  });
}
