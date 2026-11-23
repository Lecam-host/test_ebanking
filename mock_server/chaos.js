// Middleware de pannes : simule un réseau 3G instable et un serveur peu fiable.
//
// Modes :
//   none    : comportement normal
//   random  : latence 0,5–3 s, 10 % d'erreurs 500, 5 % de coupures avant traitement
//   slow    : la requête est traitée, la réponse part après 30 s
//   hang    : la requête est traitée, aucune réponse n'est jamais envoyée
//   drop    : la requête est traitée, puis la connexion est coupée sans réponse
//   down    : la connexion est coupée AVANT traitement (rien n'est créé)
//
// "count" limite le mode aux N prochaines requêtes concernées, puis retour à "none".
// Pratique en démo : { "mode": "drop", "count": 1 } ne casse que le prochain envoi.

const MODES = ['none', 'random', 'slow', 'hang', 'drop', 'down'];

const state = {
  mode: process.env.CHAOS_MODE || 'none',
  count: null, // null = illimité
  slowMs: Number(process.env.CHAOS_SLOW_MS || 30000),
};

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function consume() {
  if (state.count === null) return;
  state.count -= 1;
  if (state.count <= 0) {
    state.mode = 'none';
    state.count = null;
  }
}

function chaos(req, res, next) {
  // Les routes /admin ne sont jamais perturbées : on doit pouvoir piloter la démo.
  if (req.path.startsWith('/admin')) return next();

  const mode = state.mode;
  if (mode === 'none') return next();
  consume();

  if (mode === 'down') {
    console.log(`[chaos] down : connexion coupée avant traitement (${req.method} ${req.path})`);
    return req.socket.destroy();
  }

  if (mode === 'random') {
    return sleep(500 + Math.random() * 2500).then(() => {
      const r = Math.random();
      if (r < 0.05) {
        console.log('[chaos] random : coupure');
        return req.socket.destroy();
      }
      if (r < 0.15) {
        console.log('[chaos] random : erreur 500');
        return res.status(500).json({ error: 'internal_error' });
      }
      next();
    });
  }

  // slow, hang, drop : la route s'exécute normalement (le transfert est créé),
  // c'est l'envoi de la réponse qu'on intercepte.
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    if (mode === 'slow') {
      console.log(`[chaos] slow : réponse retardée de ${state.slowMs} ms`);
      setTimeout(() => {
        if (!res.writableEnded && !req.socket.destroyed) originalJson(body);
      }, state.slowMs);
    } else if (mode === 'hang') {
      console.log('[chaos] hang : traité, aucune réponse envoyée');
    } else if (mode === 'drop') {
      console.log('[chaos] drop : traité, connexion coupée');
      req.socket.destroy();
    }
    return res;
  };
  next();
}

function setChaos({ mode, count, slowMs }) {
  if (!MODES.includes(mode)) {
    throw new Error(`mode inconnu : ${mode}. Modes : ${MODES.join(', ')}`);
  }
  state.mode = mode;
  state.count = Number.isInteger(count) && count > 0 ? count : null;
  if (Number.isInteger(slowMs) && slowMs > 0) state.slowMs = slowMs;
  return { ...state };
}

module.exports = { chaos, setChaos, getChaos: () => ({ ...state }), MODES };
