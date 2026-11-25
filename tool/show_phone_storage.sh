#!/usr/bin/env bash
# Montre que les données gardées sur le téléphone sont illisibles hors de l'app :
# copie sur le Mac la base des transferts et le stockage sécurisé, puis essaie
# de les lire avec des outils ordinaires.
#
# Usage : ./tool/show_phone_storage.sh "Awa Kone"
#   (le nom d'un bénéficiaire qui apparaît dans l'historique de l'app)
#
# Il faut la version debug de l'app (flutter run) : sur une version release,
# Android refuse `run-as` et personne n'entre dans le dossier privé de l'app.
set -euo pipefail

app=com.example.test_ebanking
name=${1:?"Donne le nom d'un bénéficiaire de l'historique, par exemple : $0 \"Awa Kone\""}

if ! adb get-state >/dev/null 2>&1; then
  echo "Aucun téléphone : branche-le et accepte le débogage USB." >&2
  exit 1
fi
if ! adb shell run-as "$app" true >/dev/null 2>&1; then
  echo "Accès refusé au dossier de l'app : installe la version debug (flutter run)." >&2
  exit 1
fi
if ! adb shell run-as "$app" test -f files/transfers.sqlite; then
  echo "Pas encore de base : connecte-toi dans l'app pour charger l'historique." >&2
  exit 1
fi

# Copies effacées à la fin : même chiffrées, elles n'ont rien à faire sur le Mac.
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
db="$dir/transfers.sqlite"
adb exec-out run-as "$app" cat files/transfers.sqlite >"$db"

echo "== 1. Base des transferts : files/transfers.sqlite ($(wc -c <"$db" | tr -d ' ') octets)"
echo
echo "Début du fichier (une base SQLite en clair commence par « SQLite format 3 ») :"
xxd -l 32 "$db"
echo
echo "Ouverture avec sqlite3 :"
sqlite3 "$db" .tables 2>&1 || true
echo
# LC_ALL=C : recherche octet par octet dans un fichier binaire.
if LC_ALL=C grep -qF "$name" "$db"; then
  echo "« $name » est lisible dans le fichier : la base N'EST PAS chiffrée." >&2
  exit 1
fi
echo "« $name » : introuvable dans le fichier."
echo

echo "== 2. Stockage sécurisé : shared_prefs/"
echo
echo "Les noms des entrées se lisent, pas leurs valeurs : elles sont chiffrées par"
echo "une clé du Keystore d'Android, qui ne sort jamais du téléphone."
for file in $(adb shell run-as "$app" ls shared_prefs | tr -d '\r' | grep FlutterSecure); do
  echo
  echo "-- $file (valeurs coupées à 20 caractères)"
  # Le préfixe ajouté par flutter_secure_storage devant chaque nom est retiré
  # pour la lisibilité.
  adb exec-out run-as "$app" cat "shared_prefs/$file" |
    sed -E -e 's/VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg_//' \
      -e 's#(<string name="[^"]*">)([^<]{20})[^<]+#\1\2…#'
done
