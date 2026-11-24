#!/usr/bin/env bash
# Vérifie à la main l'idempotence et les modes de panne.
# Usage : lancer le serveur (npm start) dans un terminal, puis ./try.sh dans un autre.
URL=${URL:-http://localhost:3000}
H='Content-Type: application/json'
B='{"amount":25000,"currency":"XOF","recipientPhone":"0701020304","recipientName":"Awa Kone"}'
KEY="demo-$(date +%s)"
PHONE=0700000001

curl -s -X POST "$URL/admin/reset" >/dev/null

echo "== 0. Connexion : code SMS (lu via /admin/otp), puis jeton d'accès"
curl -s -X POST "$URL/auth/otp" -H "$H" -d "{\"phone\":\"$PHONE\"}"
CODE=$(curl -s "$URL/admin/otp?phone=$PHONE" | sed -E 's/.*"code":"([0-9]+)".*/\1/')
TOKEN=$(curl -s -X POST "$URL/auth/token" -H "$H" -d "{\"phone\":\"$PHONE\",\"code\":\"$CODE\"}" \
  | sed -E 's/.*"accessToken":"([^"]+)".*/\1/')
A="Authorization: Bearer $TOKEN"
curl -s -w ' [%{http_code}] sans jeton, attendu 401\n' "$URL/transfers"

echo "== 1. Deux POST avec la même clé : 201 puis 200, même id"
curl -s -w ' [%{http_code}]\n' -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-a" -d "$B"
curl -s -w ' [%{http_code}]\n' -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-a" -d "$B"

echo "== 2. drop : le transfert est créé mais la réponse est perdue"
curl -s -X POST "$URL/admin/chaos" -H "$H" -d '{"mode":"drop","count":1}' >/dev/null
curl -s -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-b" -d "$B"; echo "(curl exit $?, attendu 52)"
echo "   Reprise par la clé :"
curl -s -w ' [%{http_code}]\n' "$URL/transfers?idempotencyKey=$KEY-b" -H "$A"

echo "== 3. down : coupure avant traitement, rien n'est créé"
curl -s -X POST "$URL/admin/chaos" -H "$H" -d '{"mode":"down","count":1}' >/dev/null
curl -s -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-c" -d "$B"; echo "(curl exit $?, attendu 52)"
curl -s -w ' [%{http_code}]\n' "$URL/transfers?idempotencyKey=$KEY-c" -H "$A"

echo "== 4. slow : réponse après 30 s, le client abandonne à 5 s"
curl -s -X POST "$URL/admin/chaos" -H "$H" -d '{"mode":"slow","count":1}' >/dev/null
curl -s -m 5 -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-d" -d "$B"; echo "(curl exit $?, attendu 28)"
curl -s -w ' [%{http_code}]\n' "$URL/transfers?idempotencyKey=$KEY-d" -H "$A"

echo "== 5. Envoi à son propre numéro : 422 self_transfer"
curl -s -w ' [%{http_code}]\n' -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-e" \
  -d "{\"amount\":1000,\"currency\":\"XOF\",\"recipientPhone\":\"$PHONE\",\"recipientName\":\"Moi\"}"

echo "== 6. Montant au-dessus du solde : 422 insufficient_funds"
curl -s -w ' [%{http_code}]\n' -X POST "$URL/transfers" -H "$H" -H "$A" -H "Idempotency-Key: $KEY-f" \
  -d '{"amount":2000000,"currency":"XOF","recipientPhone":"0701020304","recipientName":"Awa Kone"}'

echo "== Total : attendu 3 transferts (a, b, d)"
curl -s "$URL/transfers" -H "$A" | grep -o '"id":"tr_' | wc -l
echo "== Solde : attendu 925000 (1 000 000 - 3 x 25 000, chaque transfert débité une seule fois)"
curl -s "$URL/transfers" -H "$A" | sed -E 's/.*"balance":([0-9]+).*/\1/'; echo
