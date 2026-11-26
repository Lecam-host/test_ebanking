import 'package:flutter/material.dart';
import 'package:test_ebanking/features/push/domain/entities/push_message.dart';

/// Bandeau affiché quand une notification arrive avec l'app ouverte.
///
/// Il décrit un instant : l'écran, lui, montre toujours le statut à jour.
/// - Un statut plus récent remplace le bandeau en cours, au lieu d'attendre
///   derrière lui dans la file.
/// - `persist: false` : avec une action, un SnackBar reste affiché par défaut
///   jusqu'à un appui ; celui-ci disparaît seul après quelques secondes.
void showPushBanner(
  ScaffoldMessengerState messenger,
  PushMessage message, {
  required VoidCallback onOpen,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message.title),
        persist: false,
        action: SnackBarAction(label: 'Voir', onPressed: onOpen),
      ),
    );
}
