import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';

/// Champ de code secret : 4 chiffres masqués.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: true,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: 4,
    decoration: InputDecoration(labelText: label),
  );
}

/// Création du code secret, juste après la première connexion.
class CreatePinPage extends ConsumerStatefulWidget {
  const CreatePinPage({super.key});

  @override
  ConsumerState<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends ConsumerState<CreatePinPage> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_pin.text != _confirmation.text) {
      setState(() => _error = 'Les deux codes sont différents.');
      return;
    }
    final result = await ref
        .read(authNotifierProvider.notifier)
        .createPin(_pin.text);
    if (!mounted) return;
    setState(
      () => _error = switch (result) {
        Err(failure: ValidationFailure(:final errors)) => errors.join('\n'),
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Code secret')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Choisissez un code secret de 4 chiffres. Il sera demandé à '
          'l\'ouverture de l\'app et à chaque envoi.',
        ),
        PinField(controller: _pin, label: 'Code secret'),
        PinField(controller: _confirmation, label: 'Confirmation'),
        if (_error != null) Text(_error!),
        FilledButton(onPressed: _create, child: const Text('Valider')),
      ],
    ),
  );
}

/// Déverrouillage : au démarrage et au retour d'arrière-plan. Fonctionne sans
/// réseau, pour que l'historique reste lisible en mode avion.
class UnlockPage extends ConsumerStatefulWidget {
  const UnlockPage({super.key});

  @override
  ConsumerState<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<UnlockPage> {
  final _pin = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final check = await ref
        .read(authNotifierProvider.notifier)
        .unlock(_pin.text);
    if (!mounted) return;
    _pin.clear();
    setState(
      () => _error = switch (check) {
        PinRejected(:final remainingAttempts) =>
          'Code incorrect. Essais restants : $remainingAttempts.',
        _ => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Déverrouiller')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PinField(controller: _pin, label: 'Code secret'),
        if (_error != null) Text(_error!),
        FilledButton(onPressed: _unlock, child: const Text('Déverrouiller')),
        TextButton(
          // Code oublié : on repart d'une connexion par SMS, tout est effacé.
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          child: const Text('Code oublié ? Se déconnecter'),
        ),
      ],
    ),
  );
}
