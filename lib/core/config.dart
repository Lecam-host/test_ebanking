/// Configuration fixée à la compilation.
abstract final class AppConfig {
  /// URL de l'API, modifiable sans toucher au code :
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
  ///
  /// Par défaut 10.0.2.2 : depuis l'émulateur Android, c'est l'adresse de la
  /// machine hôte (localhost désignerait l'émulateur lui-même).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
