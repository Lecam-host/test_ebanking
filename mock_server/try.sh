#!/usr/bin/env bash
# Vérifie à la main l'idempotence et les modes de panne.
# Usage : lancer le serveur (npm start) dans un terminal, puis ./try.sh dans un autre.
URL=${URL:-http://localhost:3000}
H='Content-Type: application/json'
B='{"amount":25000,"currency":"XOF","recipientPhone":"0701020304","recipientName":"Awa Kone"}'
KEY="demo-$(date +%s)"

curl -s -X POST "$URL/admin/reset" >/dev/null

echo "== 1. Deux POST avec la même clé : 201 puis 200, même id"
curl -s -w ' [%{http_code}]\n' -X POST "$URL/transfers" -H "$H" -H "Idempotency-Key: $KEY-a" -d "$B"
curl -s -w ' [%{http_code}]\n' -X POST "$URL/transfers" -H "$H" -H "Idempotency-Key: $KEY-a" -d "$B"

echo "== 2. drop : le transfert est créé mais la réponse est perdue"
curl -s -X POST "$URL/admin/chaos" -H "$H" -d '{"mode":"drop","count":1}' >/dev/null
curl -s -X POST "$URL/transfers" -H "$H" -H "Idempotency-Key: $KEY-b" -d "$B"; echo "(curl exit $?, attendu 52)"
echo "   Reprise par la clé :"
curl -s -w ' [%{http_code}]\n' "$URL/transfers?idempotencyKey=$KEY-b"

echo "== 3. down : coupure avant traitement, rien n'est créé"
curl -s -X POST "$URL/admin/chaos" -H "$H" -d '{"mode":"down","count":1}' >/dev/null
curl -s -X POST "$URL/transfers" -H "$H" -H "Idempotency-Key: $KEY-c" -d "$B"; echo "(curl exit $?, attendu 52)"
curl -s -w ' [%{http_code}]\n' "$URL/transfers?idempotencyKey=$KEY-c"

echo "== 4. slow : réponse après 30 s, le client abandonne à 5 s"
curl -s -X POST "$URL/admin/chaos" -H "$H" -d '{"mode":"slow","count":1}' >/dev/null
curl -s -m 5 -X POST "$URL/transfers" -H "$H" -H "Idempotency-Key: $KEY-d" -d "$B"; echo "(curl exit $?, attendu 28)"
curl -s -w ' [%{http_code}]\n' "$URL/transfers?idempotencyKey=$KEY-d"

echo "== Total : attendu 3 transferts (a, b, d)"
curl -s "$URL/transfers" | grep -o '"id":"tr_' | wc -l
