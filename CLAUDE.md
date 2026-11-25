# CLAUDE.md — test_ebanking

App Flutter (Dart 3, null safety) d'envoi d'argent international, pour des téléphones
Android modestes en 3G instable. C'est un test technique : chaque ligne doit pouvoir être
expliquée et défendue en entretien.

## Contexte et exigences

- **Clean Architecture** : présentation, domaine, données. Les dépendances pointent toujours
  vers le domaine. Le serveur, le stockage local et la gestion d'état sont des détails
  remplaçables.
- **Jamais de double envoi involontaire** d'un même transfert, quoi qu'il arrive au réseau
  ou au téléphone (app tuée juste après « Envoyer », serveur qui répond après 30 s ou jamais).
- **Historique hors ligne** : il s'affiche sans réseau, avec l'heure de sa dernière mise à jour.
- **Gestion d'état** : Riverpod, sans génération de code.
- Énoncé officiel : `~/Downloads/Test_technique_Mobile.pdf` (auth, stockage sécurisé, FCM imposé,
  design Figma, README et diagrammes exigés). Reste à faire : design, documentation.
- **Serveur simulé** : `mock_server/` (Node + Express). `mock_server/server.js` est la
  référence du contrat d'API.

## Style de code et méthode

- Code simple et lisible, sans sur-ingénierie. Rien qui ne soit pas demandé dans la phase en cours.
- Code en anglais, commentaires en français, pour expliquer le « pourquoi » quand il n'est pas évident.
- Paquets ajoutés avec `flutter pub add` (dernières versions stables). Si l'API d'un paquet a
  changé, vérifier sa doc officielle actuelle au lieu de deviner.
- Travail par phases. Fin de phase : `flutter analyze` sans erreur, `flutter test` vert, un
  commit conventionnel (`feat(transfer): ...`, `chore: ...`), puis arrêt pour validation.

## Règles d'architecture

Arborescence par fonctionnalité, puis par couche :

```
lib/core/                   Result, Failure, Clock, IdGenerator, config
lib/features/transfer/      domain/, data/, presentation/
lib/features/auth/domain/   interfaces seulement pour l'instant
lib/features/push/domain/   interfaces seulement pour l'instant
lib/app/                    app.dart, routeur, providers racine
test/                       même arborescence que lib/
```

- `domain/` est du **Dart pur**. Il n'importe jamais `package:flutter`, `package:dio`,
  `package:drift`, `package:flutter_secure_storage`, `package:firebase_*`, ni un fichier
  d'une couche `data/` ou `presentation/`.
- `domain/` contient les entités, les cas d'usage et les **ports** (interfaces) ;
  `data/` implémente ces ports.
- `presentation/` n'importe jamais `data/` : elle ne connaît que le domaine.
- `lib/app/` est le **seul** endroit qui assemble les couches (providers racine qui branchent
  les implémentations sur les interfaces).
- Les erreurs attendues (saisie, réseau, refus serveur) sont des valeurs (`Result` / `Failure`),
  pas des exceptions qui traversent les couches.
- L'heure et les identifiants passent par `Clock` et `IdGenerator`, pour être remplaçables en test.
- Ces règles sont vérifiées par `test/architecture_test.dart`.

## Choix techniques

- **Base chiffrée** : Drift sur le SQLite du paquet `sqlite3`, qui embarque SQLCipher grâce aux
  hooks de build (`hooks.user_defines.sqlite3.source` dans `pubspec.yaml`). La clé est appliquée
  à l'ouverture avec `PRAGMA key`. Ne pas ajouter `sqlcipher_flutter_libs`,
  `sqlite3_flutter_libs` ni `drift_flutter` : les deux premiers sont obsolètes, et
  `drift_flutter` les tire en dépendance. La doc Drift recommande `sqlite3mc`
  (SQLite3MultipleCiphers) ; passer de l'un à l'autre se fait en une ligne.
- **Clé de la base** : 32 octets aléatoires créés au premier lancement, gardés dans
  `flutter_secure_storage`, passés en clé brute (`PRAGMA key = "x'...'"`, sans dérivation lente).
  Une table `transfers` (outbox + cache, clé primaire `idempotencyKey`) et une table `sync_state`
  d'une ligne (date de synchro et solde). Dates stockées en secondes Unix (défaut Drift).
  Schéma version 2 : la migration depuis la version 1 ajoute la colonne `balance`.
- **Solde** : tenu par le serveur seul (`mock_server/accounts.js`, 1 000 000 FCFA à l'ouverture
  du compte), débité à la création d'un transfert, jamais au rejeu ; remboursé si FAILED. Il
  arrive avec l'historique (`GET /transfers`) : l'app affiche le dernier solde connu, avec
  l'heure de sa mise à jour, et ne bloque jamais un envoi sur ce solde, qui peut être périmé.
  `SendTransfer` reçoit `senderPhone` et refuse l'envoi à son propre numéro.
- **Erreurs Dio** : dans le doute (coupure, erreur inconnue), `NetworkFailure`, donc résultat
  inconnu, jamais un refus. Seul un 4xx (sauf 401) donne `RejectedFailure`.
- **Tests d'intégration** : tag `integration`, ignorés par défaut via `skip` dans `dart_test.yaml`.
  `exclude_tags` ne convient pas : il l'emporte sur `--tags` et plus rien ne les lancerait.
- **Session** : code SMS une fois par téléphone, puis code secret (PIN) de 4 chiffres à
  l'ouverture, au retour après 1 min d'arrière-plan et à chaque envoi. Jeton d'accès court en
  mémoire seulement ; jeton de renouvellement (rotation, usage unique) dans
  `flutter_secure_storage`. `SessionManager` renouvelle en silence (un seul échange à la fois) ;
  `AuthInterceptor` (Dio) rejoue la requête après un 401, avec la même `Idempotency-Key`.
- **Code secret** : vérifié sur le téléphone (l'historique doit s'ouvrir en mode avion), gardé en
  empreinte SHA-256 salée ; 5 essais ratés → déconnexion. Déconnexion (`SignOut`) : transferts,
  PIN et session effacés du téléphone, puis révocation côté serveur.
- **Notifications (FCM)** : firebase_messaging 17, inscription par identifiant d'installation
  (FID : `register()` / `onRegistered`, `getToken` est déprécié). Le FID est envoyé au serveur
  (`POST /devices`) et rattaché à la session : une session révoquée ne reçoit plus rien.
  Inscription ratée (serveur injoignable au démarrage) : refaite après chaque synchro réussie
  (`PushSubscription.retryIfNeeded`, déclenché par `App`). Sur Android, l'inscription par FID
  exige `firebase_messaging_installation_id_enabled` dans `AndroidManifest.xml` : sans cette
  ligne, `onRegistered` ne se déclenche jamais.
  Arrière-plan / app fermée : notification affichée par le système, l'appui ouvre
  `/transfers/<clé>` (via le déverrouillage). App ouverte : bandeau dans l'app + rafraîchissement.
  Texte neutre (ni montant ni bénéficiaire) car visible sur l'écran verrouillé.
- **Outils réseau partagés** : `lib/core/data/` (`createDio`, `failureFromDioException`). Le dossier
  s'appelle `data` pour que le test d'architecture interdise au domaine de l'importer.
- **Injection (Riverpod)** : `presentation/transfer_providers.dart` déclare les ports
  (`transferRepositoryProvider`, `transferLocalStoreProvider`, `isOnlineProvider`) sans
  implémentation et en construit les cas d'usage ; `lib/app/providers.dart` les branche
  (`overrides` du `ProviderScope`), les tests y branchent des faux.
- **Formulaire d'envoi** : `SendTransferNotifier` sans autoDispose (quitter l'écran ne crée pas
  de nouvelle clé) ; une clé par formulaire, figé dès qu'un transfert est enregistré.
- **Reprise automatique** (`AutoResume`) : au démarrage, au retour du réseau, après un envoi
  accepté (pour le solde), puis toutes les 30 s tant qu'un transfert est incertain ; un seul
  passage à la fois.
- **URL de l'API** : `--dart-define=API_BASE_URL=...` (`lib/core/config.dart`), par défaut
  `http://localhost:3000`. Simulateur iOS : rien à faire. Émulateur Android ou téléphone en
  USB : `adb reverse tcp:3000 tcp:3000` (à refaire après chaque rebranchement). Téléphone en
  Wi-Fi seulement : l'adresse IP du Mac. HTTP en clair est autorisé seulement dans
  `android/app/src/debug/AndroidManifest.xml`.

## Invariants d'envoi (le cœur du test)

Chaque transfert a une **clé d'idempotence** (UUID v4) : c'est son identifiant local stable,
envoyé au serveur dans l'en-tête `Idempotency-Key`.

1. **Une clé par intention d'envoi.** Générée une seule fois par formulaire (pas à chaque
   appui), réutilisée pour « Réessayer » et pour toutes les reprises. Nouvelle clé seulement
   pour un nouveau transfert. Une reprise ne génère **jamais** de nouvelle clé. Le domaine
   n'en fabrique jamais : `SendTransfer` la reçoit de l'appelant.
2. **Saisie invalide** (ou envoi à son propre numéro) → `ValidationFailure` : rien n'est écrit,
   aucun appel réseau.
3. **Clé déjà connue localement** → pas de deuxième transfert. S'il est encore à réconcilier,
   on relance sa réconciliation ; sinon on renvoie son état.
4. **Écrire avant d'appeler.** Le transfert est enregistré en `pendingSubmission` AVANT tout
   appel réseau : si l'app est tuée pendant l'envoi, la reprise le retrouvera.
5. **Pas de réponse n'est pas un échec.** Coupure (`NetworkFailure`), délai dépassé
   (`TimeoutFailure`) ou 5xx (`ServerFailure`) → `unknownOutcome`, affiché « Vérification en
   cours ». Jamais `failed` : le serveur a peut-être créé le transfert.
6. **Refus métier 4xx** (`RejectedFailure`, avec le code d'erreur du serveur) → `rejected`, final.
7. **Reprise** (`ResumePendingTransfers`), pour chaque transfert `pendingSubmission` ou
   `unknownOutcome` :
   - on demande d'abord au serveur (`GET /transfers?idempotencyKey=`) ;
   - trouvé → mise à jour locale (serverId, statut), **sans renvoi** ;
   - inconnu (404) → `POST /transfers` rejoué avec la **même clé** et le **même contenu** ;
   - erreur réseau ou serveur → passe ou reste en `unknownOutcome`, et ce passage s'arrête.
8. **Même contenu au rejeu.** Le serveur refuse une clé réutilisée avec un contenu différent
   (422 `idempotency_key_reused`) : le stockage local conserve donc la requête exacte.
9. **Écritures locales idempotentes** par `idempotencyKey` : réécrire le même transfert ne
   crée jamais de doublon.
10. **`connectivity_plus` est un déclencheur, jamais une vérité** : seul le serveur dit si un
    transfert existe.
11. **Une seule façon d'envoyer** : `TransferSender` (`submit` et `reconcile`), partagé par
    `SendTransfer` et `ResumePendingTransfers`. Il renvoie `Ok(transfert)` y compris en
    `unknownOutcome`, et `Err` seulement pour un refus (`rejected`) ou une session invalide.

### Statuts

| `TransferStatus` (local) | Statut serveur | Sens |
|---|---|---|
| `pendingSubmission` | — | enregistré sur le téléphone, pas encore confirmé |
| `unknownOutcome` | — | envoyé, résultat inconnu |
| `submitted` | `SUBMITTED` | accepté par le serveur |
| `processing` | `PROCESSING` | en cours |
| `paid` | `PAID` | final |
| `failed` | `FAILED` | final |
| `rejected` | — (refus 4xx) | final |

`isFinal` : paid, failed, rejected. `needsReconciliation` : pendingSubmission, unknownOutcome.

## Contrat d'API (résumé de `mock_server/server.js`)

Transfert JSON : `{ id, idempotencyKey, amount, currency, recipientPhone, recipientName,
status, createdAt, updatedAt }`. `amount` est un entier en FCFA, `currency` vaut `"XOF"`,
les dates sont en ISO 8601.

Les routes `/transfers` exigent `Authorization: Bearer <jeton d'accès>` (401 `unauthorized`,
`token_expired` ou `session_revoked`) ; chaque client ne voit que ses transferts. Auth dans
`mock_server/auth.js`.

| Route | Réponses |
|---|---|
| `POST /auth/otp` `{ phone }` | 204 ; le code SMS est écrit dans la console du serveur |
| `POST /auth/token` `{ phone, code }` | 200 `{ accessToken, refreshToken, expiresIn }` ; 401 `otp_invalid` ; 429 après 5 essais |
| `POST /auth/refresh` `{ refreshToken }` | 200 nouveaux jetons (l'ancien est consommé) ; un jeton réutilisé révoque la session |
| `POST /auth/logout` `{ refreshToken }` | 204, session révoquée |
| `GET /admin/otp?phone=` | dernier code SMS (démo, tests) |
| `POST /admin/sessions/expire` | tous les jetons d'accès expirent (démo « session expirée ») |
| `POST /admin/sessions/revoke` `{ phone }` | révoque les sessions d'un numéro (démo « téléphone volé ») |
| `POST /devices` `{ fid }` (jeton requis) | 204 : téléphone inscrit aux notifications de sa session |
| `GET /admin/transfers` | tous les transferts (pour `advance.sh`) |
| `POST /transfers` + en-tête `Idempotency-Key` | 201 créé (montant débité) ; 200 doublon reconnu (le transfert existant est renvoyé, rien n'est redébité) ; 400 `idempotency_key_required` ; 422 `validation_error` (avec `details`) ; 422 `idempotency_key_reused` ; 422 `self_transfer` ; 422 `insufficient_funds` (avec `balance`) |
| `GET /transfers` | 200 `{ items: [...], serverTime, balance }`, du plus récent au plus ancien |
| `GET /transfers?idempotencyKey=K` | 200 transfert ; 404 `not_found` si la clé est inconnue |
| `GET /transfers/:id` | 200 transfert ; 404 `not_found` |
| `POST /admin/reset` | vide tout (les comptes repartent à 1 000 000 FCFA) et remet le chaos à `none` |
| `GET` / `POST /admin/chaos` | lit / règle `{ mode, count?, slowMs? }` |
| `POST /admin/transfers/:id/advance` | SUBMITTED → PROCESSING → PAID, ou `{ status }` imposé ; FAILED rembourse ; 409 `final_status` sur PAID ou FAILED ; envoie la notification FCM (`mock_server/push.js`, API HTTP v1, cible `fid`) |
| `POST /admin/accounts/credit` `{ phone, amount }` | recrédite un compte (démo) ; 200 `{ phone, balance }` |

Modes de chaos (jamais appliqués aux routes `/admin`) : `none` ; `random` (latence 0,5–3 s,
10 % d'erreurs 500, 5 % de coupures) ; `slow` (traité, réponse après 30 s) ; `hang` (traité,
aucune réponse) ; `drop` (traité, puis connexion coupée) ; `down` (coupé avant traitement,
rien n'est créé). `count` limite le mode aux N prochaines requêtes.

À savoir : le serveur ne retient une clé d'idempotence que 24 h (purge lors d'un POST
suivant). Au-delà, une reprise qui reçoit 404 recréerait le transfert.

## Commandes utiles

```bash
flutter analyze
flutter test                      # tests unitaires et de widgets
flutter test --tags integration --run-skipped   # tests d'intégration (serveur simulé sur localhost:3000)
# Ils remettent le serveur à zéro : pour garder celui de la démo, en lancer un autre
# (PORT=3100 npm start) et le viser avec MOCK_SERVER_URL=http://localhost:3100.
dart run build_runner build       # régénère le code Drift (*.g.dart, commité) après un changement de table
cd mock_server && npm start       # serveur simulé (npm install la première fois)
cd mock_server && ./try.sh        # vérification manuelle de l'idempotence et des pannes
cd mock_server && ./advance.sh    # fait avancer le dernier transfert → notification FCM
adb reverse tcp:3000 tcp:3000    # émulateur Android ou téléphone en USB : localhost → le Mac
flutter run --dart-define=API_BASE_URL=http://<ip-du-mac>:3000   # vrai téléphone, même Wi-Fi
```

## Interdits

- Aucune clé réelle (API, jeton, compte de service) dans le code, les tests ou les commits.
- `mock_server/service-account.json` n'est **jamais** commité (il est ignoré par `.gitignore`).
- Ne rien modifier dans `mock_server/` sans accord explicite.
- Pas de génération de code pour Riverpod (ni `riverpod_generator`, ni annotations).
- Pas de HTTP en clair hors debug.
