import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_ebanking/core/failure.dart';
import 'package:test_ebanking/core/result.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';

/// Connexion : numéro de téléphone, puis code reçu par SMS. Une seule fois par
/// téléphone ; ensuite, le code secret suffit.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(message),
            ),
          TextField(
            controller: _phone,
            enabled: !_codeSent && !_busy,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 10,
            decoration: const InputDecoration(labelText: 'Numéro de téléphone'),
          ),
          if (_codeSent)
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Code reçu par SMS'),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!),
            ),
          FilledButton(
            onPressed: _busy ? null : (_codeSent ? _signIn : _requestCode),
            child: Text(_codeSent ? 'Se connecter' : 'Recevoir le code'),
          ),
          if (_codeSent)
            TextButton(
              onPressed: _busy ? null : _requestCode,
              child: const Text('Renvoyer le code'),
            ),
        ],
      ),
    );
  }
}
