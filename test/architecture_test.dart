// Fait respecter les règles de dépendance de la Clean Architecture (CLAUDE.md).
//
// On lit simplement les directives import/export de chaque fichier de lib/.
// Le groupe « le détecteur » prouve que la vérification attrape bien les
// violations : sans lui, ce test passerait aussi s'il ne vérifiait rien.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _packageName = 'test_ebanking';

/// Préfixes interdits dans domain/ : UI, réseau, stockage et push sont des
/// détails qui doivent rester remplaçables.
const _forbiddenInDomain = [
  'package:flutter/',
  'package:dio/',
  'package:drift/',
  'package:flutter_secure_storage/',
  'package:firebase_', // tous les paquets firebase_*
];

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Couche d'un fichier d'après ses dossiers : domain, data, presentation,
/// ou null (core/, app/, main.dart).
String? _layerOf(String path) {
  final folders = path.split('/')..removeLast();
  for (final layer in const ['domain', 'data', 'presentation']) {
    if (folders.contains(layer)) return layer;
  }
  return null;
}

/// Chemin du fichier du projet visé par [uri], ou null si [uri] désigne
/// dart: ou un autre paquet.
String? _localTarget(String fromPath, String uri) {
  const prefix = 'package:$_packageName/';
  if (uri.startsWith(prefix)) return 'lib/${uri.substring(prefix.length)}';
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  // Import relatif : résolu depuis le fichier qui l'écrit.
  return Uri.parse(fromPath).resolve(uri).path;
}

/// Liste les imports de [source] (contenu du fichier [path]) qui violent les
/// règles de dépendance.
List<String> dependencyViolations(String path, String source) {
  final layer = _layerOf(path);
  final violations = <String>[];

  for (final match in _directive.allMatches(source)) {
    final uri = match.group(1)!;
    final target = _localTarget(path, uri);
    final targetLayer = target == null ? null : _layerOf(target);

    final isViolation = switch (layer) {
      'domain' =>
        _forbiddenInDomain.any(uri.startsWith) ||
            targetLayer == 'data' ||
            targetLayer == 'presentation',
      'presentation' => targetLayer == 'data',
      _ => false,
    };
    if (isViolation) violations.add('$path importe $uri');
  }
  return violations;
}

void main() {
  test('lib/ respecte les règles de dépendance', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final violations = [
      for (final file in files)
        ...dependencyViolations(
          file.path.replaceAll(r'\', '/'), // chemins Windows
          file.readAsStringSync(),
        ),
    ];

    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('le détecteur', () {
    const domainFile = 'lib/features/transfer/domain/send_transfer.dart';
    const presentationFile =
        'lib/features/transfer/presentation/send_page.dart';

    List<String> check(String path, String uri) =>
        dependencyViolations(path, "import '$uri';");

    test('refuse les paquets techniques dans domain/', () {
      for (final uri in [
        'package:flutter/foundation.dart',
        'package:dio/dio.dart',
        'package:drift/drift.dart',
        'package:flutter_secure_storage/flutter_secure_storage.dart',
        'package:firebase_messaging/firebase_messaging.dart',
      ]) {
        expect(check(domainFile, uri), isNotEmpty, reason: uri);
      }
    });

    test(
      'refuse data/ et presentation/ dans domain/, en relatif ou en package:',
      () {
        for (final uri in [
          '../data/transfer_api.dart',
          '../presentation/send_page.dart',
          '../../auth/data/session_store_impl.dart',
          'package:test_ebanking/features/transfer/data/transfer_api.dart',
          'package:test_ebanking/features/transfer/presentation/send_page.dart',
        ]) {
          expect(check(domainFile, uri), isNotEmpty, reason: uri);
        }
      },
    );

    test('accepte dart:, core/ et le domaine dans domain/', () {
      for (final uri in [
        'dart:async',
        '../../../core/result.dart',
        'package:test_ebanking/core/failure.dart',
        'transfer.dart',
      ]) {
        expect(check(domainFile, uri), isEmpty, reason: uri);
      }
    });

    test('refuse data/ dans presentation/, accepte domain/', () {
      expect(check(presentationFile, '../data/transfer_api.dart'), isNotEmpty);
      expect(check(presentationFile, '../domain/send_transfer.dart'), isEmpty);
    });

    test('lit aussi les export', () {
      expect(
        dependencyViolations(domainFile, "export 'package:dio/dio.dart';"),
        isNotEmpty,
      );
    });
  });
}
