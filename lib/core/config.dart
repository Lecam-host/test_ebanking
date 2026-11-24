/// Configuration fixée à la compilation.
abstract final class AppConfig {
  /// URL de l'API, modifiable sans toucher au code :
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
  ///
  /// Par défaut localhost, qui désigne l'appareil lui-même :
  /// - simulateur iOS : il partage le réseau du Mac, rien à faire ;
  /// - émulateur Android ou téléphone en USB : `adb reverse tcp:3000 tcp:3000`
  ///   renvoie le port 3000 de l'appareil vers le Mac ;
  /// - téléphone en Wi-Fi seulement : passer l'adresse IP du Mac (ci-dessus).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
