import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/presentation/app_colors.dart';
import 'package:test_ebanking/core/presentation/sheet_scaffold.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/widgets/welcome_illustration.dart';

/// Connexion : numéro de téléphone, puis code reçu par SMS. Une seule fois par
/// téléphone ; ensuite, le code secret suffit.
///
/// Écran « Sign up » du kit Figma, adapté à ce parcours : pas de mot de passe
/// ni de nom, mais le numéro puis le code SMS.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Comme sur la maquette, le bouton reste grisé tant que le champ est vide.
  /// Le format, lui, n'est vérifié qu'à un seul endroit : le domaine.
  bool get _canSubmit =>
      !_busy && (_codeSent ? _code.text.isNotEmpty : _phone.text.isNotEmpty);

  Future<void> _run(Future<Result<void>> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (result) {
        Ok() => null,
        Err(failure: ValidationFailure(:final errors)) => errors.join('\n'),
        Err(failure: UnauthorizedFailure()) => 'Code incorrect ou expiré.',
        Err(failure: RejectedFailure(code: 'otp_attempts_exceeded')) =>
          'Trop d\'essais : demandez un nouveau code.',
        Err() => 'Serveur injoignable, réessayez.',
      };
    });
  }

  Future<void> _requestCode() => _run(() async {
    final result = await ref
        .read(authNotifierProvider.notifier)
        .requestOtp(_phone.text);
    if (result is Ok && mounted) setState(() => _codeSent = true);
    return result;
  });

  Future<void> _signIn() => _run(
    () =>
        ref.read(authNotifierProvider.notifier).signIn(_phone.text, _code.text),
  );

  @override
  Widget build(BuildContext context) {
    final message = ref.watch(authNotifierProvider).message;
    return SheetScaffold(
      title: 'Connexion',
      headline: 'Bienvenue,',
      subtitle: 'Connectez-vous avec votre numéro de téléphone',
      children: [
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(message, style: const TextStyle(color: AppColors.red)),
          ),
        const SizedBox(height: 24),
        const WelcomeIllustration(),
        const SizedBox(height: 32),
        TextField(
          controller: _phone,
          enabled: !_codeSent && !_busy,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Numéro de téléphone',
            // Indicatif toujours visible, comme le « (+84) » de la maquette ;
            // le numéro saisi reste le format national à 10 chiffres.
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 12, right: 6),
              child: Text(
                '(+225)',
                style: TextStyle(color: AppColors.text, fontSize: 14),
              ),
            ),
            prefixIconConstraints: BoxConstraints(),
            counterText: '',
          ),
        ),
        if (_codeSent) ...[
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Code reçu par SMS',
              counterText: '',
            ),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: AppColors.red)),
          ),
        const SizedBox(height: 36),
        FilledButton(
          onPressed: _canSubmit ? (_codeSent ? _signIn : _requestCode) : null,
          child: Text(_codeSent ? 'Se connecter' : 'Recevoir le code'),
        ),
        if (_codeSent) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Code non reçu ?',
                style: TextStyle(color: AppColors.text, fontSize: 12),
              ),
              TextButton(
                onPressed: _busy ? null : _requestCode,
                child: const Text('Renvoyer'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
