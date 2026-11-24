const express = require('express');
const crypto = require('crypto');
const { chaos, setChaos, getChaos } = require('./chaos');
const { registerAuthRoutes, requireAuth, resetAuth } = require('./auth');

const app = express();
app.use(express.json());

// Journal simple de chaque requête, utile pendant la démo.
app.use((req, _res, next) => {
  const key = req.get('Idempotency-Key');
  console.log(`${new Date().toISOString()} ${req.method} ${req.originalUrl}${key ? ` key=${key}` : ''}`);
  next();
});

app.use(chaos);

// Connexion (code SMS, jetons). Les transferts exigent ensuite un jeton d'accès,
// et chaque client ne voit que les siens (req.phone).
registerAuthRoutes(app);
app.use('/transfers', requireAuth);

// ---------------------------------------------------------------------------
// Stockage en mémoire (remplaçable par une vraie base plus tard).
// ---------------------------------------------------------------------------
const transfers = new Map(); // id -> transfert
const byIdempotencyKey = new Map(); // clé -> id du transfert

const IDEMPOTENCY_TTL_MS = 24 * 60 * 60 * 1000; // une clé est retenue 24 h

// Empreinte du contenu : une même clé avec un contenu différent est une erreur client.
function fingerprint({ amount, currency, recipientPhone, recipientName }) {
  return crypto
    .createHash('sha256')
    .update(JSON.stringify([amount, currency, recipientPhone, recipientName]))
    .digest('hex');
}

function validate(body) {
  const errors = [];
  if (!Number.isInteger(body.amount) || body.amount <= 0) errors.push('amount doit être un entier positif (en unités, ex. FCFA)');
  if (typeof body.currency !== 'string' || body.currency.length !== 3) errors.push('currency doit être un code ISO à 3 lettres');
  if (typeof body.recipientPhone !== 'string' || body.recipientPhone.length < 8) errors.push('recipientPhone invalide');
  if (typeof body.recipientName !== 'string' || body.recipientName.trim() === '') errors.push('recipientName requis');
  return errors;
}

function purgeExpiredKeys() {
  const now = Date.now();
  for (const [key, id] of byIdempotencyKey) {
    const t = transfers.get(id);
    if (!t || now - Date.parse(t.createdAt) > IDEMPOTENCY_TTL_MS) byIdempotencyKey.delete(key);
  }
}

// ---------------------------------------------------------------------------
// Transferts
// ---------------------------------------------------------------------------

// Création idempotente.
// Important : la vérification de la clé et l'insertion se font sans "await" entre les deux.
// Node exécute ce bloc d'un seul tenant, donc deux requêtes simultanées avec la même clé
// ne peuvent pas créer deux transferts.
app.post('/transfers', (req, res) => {
  const key = req.get('Idempotency-Key');
  if (!key) {
    return res.status(400).json({ error: 'idempotency_key_required', message: "L'en-tête Idempotency-Key est obligatoire" });
  }

  const errors = validate(req.body || {});
  if (errors.length) return res.status(422).json({ error: 'validation_error', details: errors });

  purgeExpiredKeys();
  const fp = fingerprint(req.body);

  const existingId = byIdempotencyKey.get(key);
  if (existingId) {
    const existing = transfers.get(existingId);
    if (existing.fingerprint !== fp || existing.owner !== req.phone) {
      // Même clé, contenu différent : on refuse plutôt que de deviner.
      return res.status(422).json({
        error: 'idempotency_key_reused',
        message: 'Cette clé a déjà servi pour un transfert différent',
      });
    }
    console.log(`  -> doublon reconnu, transfert existant ${existing.id} renvoyé`);
    return res.status(200).json(toPublic(existing));
  }

  const now = new Date().toISOString();
  const transfer = {
    id: `tr_${crypto.randomUUID()}`,
    idempotencyKey: key,
    fingerprint: fp,
    owner: req.phone,
    amount: req.body.amount,
    currency: req.body.currency,
    recipientPhone: req.body.recipientPhone,
    recipientName: req.body.recipientName,
    status: 'SUBMITTED',
    createdAt: now,
    updatedAt: now,
  };
  transfers.set(transfer.id, transfer);
  byIdempotencyKey.set(key, transfer.id);
  console.log(`  -> transfert créé ${transfer.id}`);

  return res.status(201).json(toPublic(transfer));
});

// Liste (historique) ou recherche par clé d'idempotence (reprise après coupure).
app.get('/transfers', (req, res) => {
  const { idempotencyKey } = req.query;
  if (idempotencyKey) {
    const t = transfers.get(byIdempotencyKey.get(idempotencyKey));
    if (!t || t.owner !== req.phone) return res.status(404).json({ error: 'not_found' });
    return res.json(toPublic(t));
  }
  const list = [...transfers.values()]
    .filter((t) => t.owner === req.phone)
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
    .map(toPublic);
  return res.json({ items: list, serverTime: new Date().toISOString() });
});

app.get('/transfers/:id', (req, res) => {
  const t = transfers.get(req.params.id);
  if (!t || t.owner !== req.phone) return res.status(404).json({ error: 'not_found' });
  return res.json(toPublic(t));
});

function toPublic(t) {
  const { fingerprint: _fp, owner: _owner, ...rest } = t;
  return rest;
}

// ---------------------------------------------------------------------------
// Administration (pilotage de la démo, jamais perturbé par le chaos)
// ---------------------------------------------------------------------------

// Fait avancer le statut d'un transfert. L'envoi FCM sera branché ici plus tard.
const NEXT_STATUS = { SUBMITTED: 'PROCESSING', PROCESSING: 'PAID' };

app.post('/admin/transfers/:id/advance', (req, res) => {
  const t = transfers.get(req.params.id);
  if (!t) return res.status(404).json({ error: 'not_found' });
  const target = req.body?.status || NEXT_STATUS[t.status];
  if (!target) return res.status(409).json({ error: 'final_status', status: t.status });
  t.status = target;
  t.updatedAt = new Date().toISOString();
  console.log(`  -> ${t.id} passe à ${t.status}`);
  return res.json(toPublic(t));
});

app.get('/admin/chaos', (_req, res) => res.json(getChaos()));

app.post('/admin/chaos', (req, res) => {
  try {
    const state = setChaos(req.body || {});
    console.log(`[chaos] mode=${state.mode} count=${state.count ?? 'illimité'}`);
    return res.json(state);
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

app.post('/admin/reset', (_req, res) => {
  transfers.clear();
  byIdempotencyKey.clear();
  resetAuth();
  setChaos({ mode: 'none' });
  return res.json({ ok: true });
});

const PORT = Number(process.env.PORT || 3000);
// 0.0.0.0 pour être joignable depuis un vrai téléphone sur le même Wi-Fi.
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Serveur simulé sur http://localhost:${PORT} (chaos : ${getChaos().mode})`);
});
