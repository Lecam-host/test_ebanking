import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/sheet_scaffold.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/domain/entities/pin_check.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/widgets/welcome_illustration.dart';

/// Champ de code secret : 4 chiffres masqués.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: true,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    maxLength: 4,
    onChanged: onChanged,
    decoration: InputDecoration(hintText: label, counterText: ''),
  );
}

Widget _errorText(String? message) => message == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(message, style: const TextStyle(color: AppColors.red)),
      );

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
  Widget build(BuildContext context) => SheetScaffold(
    title: 'Code secret',
    headline: 'Votre code secret,',
    subtitle: '4 chiffres, demandés à l\'ouverture de l\'app et à chaque envoi',
    children: [
      const SizedBox(height: 24),
      const WelcomeIllustration(),
      const SizedBox(height: 32),
      PinField(
        controller: _pin,
        label: 'Code secret',
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      PinField(
        controller: _confirmation,
        label: 'Confirmation',
        onChanged: (_) => setState(() {}),
      ),
      _errorText(_error),
      const SizedBox(height: 36),
      FilledButton(
        onPressed: _pin.text.isEmpty || _confirmation.text.isEmpty
            ? null
            : _create,
        child: const Text('Valider'),
      ),
    ],
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
  Widget build(BuildContext context) => SheetScaffold(
    title: 'Déverrouiller',
    headline: 'Bon retour,',
    subtitle: 'Entrez votre code secret pour continuer',
    children: [
      const SizedBox(height: 24),
      const WelcomeIllustration(),
      const SizedBox(height: 32),
      PinField(
        controller: _pin,
        label: 'Code secret',
        onChanged: (_) => setState(() {}),
      ),
      _errorText(_error),
      const SizedBox(height: 36),
      FilledButton(
        onPressed: _pin.text.isEmpty ? null : _unlock,
        child: const Text('Déverrouiller'),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Code oublié ?',
            style: TextStyle(color: AppColors.text, fontSize: 12),
          ),
          TextButton(
            // On repart d'une connexion par SMS : tout est effacé.
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    ],
  );
}
