import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/push/presentation/push_providers.dart';

/// Inscrit le téléphone aux notifications dès qu'une session est ouverte
/// (connexion, ou session relue au démarrage). Gardé actif par App.
final pushActivationProvider = Provider<void>((ref) {
  ref.listen(authNotifierProvider.select((auth) => auth.status.isSignedIn), (
    wasSignedIn,
    isSignedIn,
  ) {
    if (isSignedIn && wasSignedIn != true) {
      ref.read(pushSubscriptionProvider).enable();
    }
  }, fireImmediately: true);
});
