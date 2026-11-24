// Authentification simulée : code SMS (OTP), puis jetons.
//
// - Le code SMS n'est pas vraiment envoyé : il est écrit dans la console et
//   lisible via GET /admin/otp (démo et tests).
// - Le jeton d'accès est court (5 min par défaut, ACCESS_TTL_MS pour changer) :
//   volé, il ne sert pas longtemps.
// - Le jeton de renouvellement (30 jours) change à chaque usage (rotation). S'il
//   resservait, c'est qu'il a été copié : toute la session est alors révoquée.
const crypto = require('crypto');

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;
const ACCESS_TTL_MS = Number(process.env.ACCESS_TTL_MS || 5 * 60 * 1000);
const REFRESH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

const otps = new Map(); // téléphone -> { code, expiresAt, attempts }
const sessions = new Map(); // id de session -> { phone, revoked, expiresAt }
const accessTokens = new Map(); // jeton -> { sessionId, expiresAt }
const refreshTokens = new Map(); // jeton -> { sessionId, used }

const newToken = () => crypto.randomBytes(32).toString('base64url');
const isIvorianPhone = (phone) => typeof phone === 'string' && /^\d{10}$/.test(phone);

function issueTokens(sessionId) {
  const accessToken = newToken();
  const refreshToken = newToken();
  accessTokens.set(accessToken, { sessionId, expiresAt: Date.now() + ACCESS_TTL_MS });
  refreshTokens.set(refreshToken, { sessionId, used: false });
  return { accessToken, refreshToken, expiresIn: Math.round(ACCESS_TTL_MS / 1000) };
}

function revokeSession(sessionId) {
  const session = sessions.get(sessionId);
  if (session) session.revoked = true;
}

// Exige un jeton d'accès valide et place le numéro du client dans req.phone.
function requireAuth(req, res, next) {
  const match = /^Bearer (.+)$/.exec(req.get('Authorization') || '');
  const access = match && accessTokens.get(match[1]);
  if (!access) return res.status(401).json({ error: 'unauthorized' });
  const session = sessions.get(access.sessionId);
  if (!session || session.revoked) return res.status(401).json({ error: 'session_revoked' });
  if (Date.now() > access.expiresAt) return res.status(401).json({ error: 'token_expired' });
  req.phone = session.phone;
  next();
}

function registerAuthRoutes(app) {
  app.post('/auth/otp', (req, res) => {
    const { phone } = req.body || {};
    if (!isIvorianPhone(phone)) return res.status(422).json({ error: 'invalid_phone' });
    const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    otps.set(phone, { code, expiresAt: Date.now() + OTP_TTL_MS, attempts: 0 });
    console.log(`  -> [SMS simulé] ${phone} : code ${code}`);
    return res.status(204).end();
  });

  app.post('/auth/token', (req, res) => {
    const { phone, code } = req.body || {};
    const otp = otps.get(phone);
    if (!otp || Date.now() > otp.expiresAt) return res.status(401).json({ error: 'otp_invalid' });
    otp.attempts += 1;
    if (otp.attempts > OTP_MAX_ATTEMPTS) {
      otps.delete(phone);
      return res.status(429).json({ error: 'otp_attempts_exceeded' });
    }
    if (otp.code !== code) return res.status(401).json({ error: 'otp_invalid' });

    otps.delete(phone);
    const sessionId = crypto.randomUUID();
    sessions.set(sessionId, { phone, revoked: false, expiresAt: Date.now() + REFRESH_TTL_MS });
    console.log(`  -> session ouverte pour ${phone}`);
    return res.json(issueTokens(sessionId));
  });

  app.post('/auth/refresh', (req, res) => {
    const refresh = refreshTokens.get((req.body || {}).refreshToken);
    if (!refresh) return res.status(401).json({ error: 'refresh_invalid' });
    if (refresh.used) {
      // Un jeton déjà échangé qui revient : il a été copié. On coupe la session.
      revokeSession(refresh.sessionId);
      console.log('  -> jeton de renouvellement réutilisé : session révoquée');
      return res.status(401).json({ error: 'session_revoked' });
    }
    const session = sessions.get(refresh.sessionId);
    if (!session || session.revoked || Date.now() > session.expiresAt) {
      return res.status(401).json({ error: 'session_revoked' });
    }
    refresh.used = true;
    return res.json(issueTokens(refresh.sessionId));
  });

  // Sans jeton d'accès : la déconnexion doit marcher même s'il a expiré.
  app.post('/auth/logout', (req, res) => {
    const refresh = refreshTokens.get((req.body || {}).refreshToken);
    if (refresh) revokeSession(refresh.sessionId);
    return res.status(204).end();
  });

  // --- Administration (démo et tests ; jamais perturbée par le chaos) ---

  // Le « SMS » : le dernier code envoyé à ce numéro.
  app.get('/admin/otp', (req, res) => {
    const otp = otps.get(req.query.phone);
    if (!otp) return res.status(404).json({ error: 'not_found' });
    return res.json({ code: otp.code });
  });

  // « La session expire pendant l'utilisation » : tous les jetons d'accès expirent.
  app.post('/admin/sessions/expire', (_req, res) => {
    for (const access of accessTokens.values()) access.expiresAt = 0;
    console.log('[admin] jetons d\'accès expirés');
    return res.json({ ok: true });
  });

  // « Téléphone volé » : le support coupe toutes les sessions d'un numéro.
  app.post('/admin/sessions/revoke', (req, res) => {
    const { phone } = req.body || {};
    let revoked = 0;
    for (const session of sessions.values()) {
      if (session.phone === phone && !session.revoked) {
        session.revoked = true;
        revoked += 1;
      }
    }
    console.log(`[admin] ${revoked} session(s) révoquée(s) pour ${phone}`);
    return res.json({ revoked });
  });
}

function resetAuth() {
  otps.clear();
  sessions.clear();
  accessTokens.clear();
  refreshTokens.clear();
}

module.exports = { registerAuthRoutes, requireAuth, resetAuth };
