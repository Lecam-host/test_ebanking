import 'package:uuid/uuid.dart';

/// Fabrique d'identifiants, injectée pour obtenir des clés prévisibles en test.
abstract interface class IdGenerator {
  String newId();
}

/// UUID v4 : 122 bits tirés d'un générateur aléatoire cryptographique. Une
/// collision est si improbable que le téléphone peut créer seul une clé
/// d'idempotence unique, sans demander quoi que ce soit au serveur.
class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
