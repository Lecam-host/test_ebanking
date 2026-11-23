import 'package:flutter/material.dart';

/// Racine de l'application. Le routeur et les providers racine viendront ici ;
/// en attendant, un écran vide.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'test_ebanking',
      home: Scaffold(body: Center(child: Text('test_ebanking'))),
    );
  }
}
