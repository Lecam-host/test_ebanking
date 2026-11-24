import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_ebanking/core/presentation/app_theme.dart';
import 'package:test_ebanking/features/auth/presentation/auth_notifier.dart';
import 'package:test_ebanking/features/auth/presentation/pages/login_page.dart';

import '../../auth_fakes.dart';

void main() {
  testWidgets('bouton grisé tant que le numéro est vide, puis demande du '
      'code SMS et passage à la saisie du code', (tester) async {
    final auth = FixedAuthNotifier(AuthStatus.signedOut);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => auth)],
        child: MaterialApp(theme: buildAppTheme(), home: const LoginPage()),
      ),
    );
    FilledButton button() => tester.widget(find.byType(FilledButton));

    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '0701020304');
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.text('Recevoir le code'));
    await tester.pumpAndSettle();

    expect(auth.otpRequests, ['0701020304']);
    expect(find.text('Code reçu par SMS'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(button().onPressed, isNull); // code encore vide
  });
}
