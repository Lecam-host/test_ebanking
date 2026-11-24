#!/usr/bin/env bash
# Fait avancer le statut d'un transfert (SUBMITTED -> PROCESSING -> PAID) : le
# serveur simulé prévient alors le client par une notification FCM.
#
# Usage (serveur lancé avec npm start) :
#   ./advance.sh            le transfert le plus récent
#   ./advance.sh tr_xxx     un transfert précis
#   STATUS=FAILED ./advance.sh tr_xxx   impose un statut
URL=${URL:-http://localhost:3000}
ID=$1

if [ -z "$ID" ]; then
  ID=$(curl -s "$URL/admin/transfers" | sed -nE 's/^[^[]*\[\{"id":"([^"]+)".*/\1/p')
  if [ -z "$ID" ]; then
    echo "Aucun transfert sur le serveur."
    exit 1
  fi
fi

BODY='{}'
[ -n "$STATUS" ] && BODY="{\"status\":\"$STATUS\"}"

curl -s -w ' [%{http_code}]\n' -X POST "$URL/admin/transfers/$ID/advance" \
  -H 'Content-Type: application/json' -d "$BODY"
echo "(résultat de l'envoi FCM dans la console du serveur)"
