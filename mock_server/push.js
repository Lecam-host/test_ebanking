// Notifications push via l'API FCM HTTP v1.
//
// - Chaque téléphone s'inscrit (POST /devices) avec son identifiant FCM (FID,
//   « Firebase Installation ID », qui remplace l'ancien jeton), rattaché à SA
//   session : une session révoquée (déconnexion, téléphone volé) ne reçoit
//   plus rien, même si le téléphone n'a pas pu se désinscrire.
// - L'envoi s'authentifie avec le compte de service du projet Firebase
//   (service-account.json, jamais commité), via la bibliothèque officielle de
//   Google plutôt qu'une signature JWT écrite à la main.
const fs = require('fs');
const path = require('path');
const { GoogleAuth } = require('google-auth-library');
const { requireAuth, isSessionActive } = require('./auth');

const KEY_FILE =
  process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, 'service-account.json');

const devices = new Map(); // FID -> { phone, sessionId }

// Texte neutre : il s'affiche sur l'écran verrouillé, sans montant ni bénéficiaire.
const TITLES = {
  SUBMITTED: 'Transfert enregistré',
  PROCESSING: 'Transfert en cours de traitement',
  PAID: 'Transfert payé',
  FAILED: 'Transfert échoué',
};

let googleAuth;
function getAuth() {
  if (!fs.existsSync(KEY_FILE)) return null;
  googleAuth ??= new GoogleAuth({
    keyFile: KEY_FILE,
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  });
  return googleAuth;
}

function registerPushRoutes(app) {
  app.post('/devices', requireAuth, (req, res) => {
    const { fid } = req.body || {};
    if (typeof fid !== 'string' || fid === '') {
      return res.status(422).json({ error: 'invalid_fid' });
    }
    devices.set(fid, { phone: req.phone, sessionId: req.sessionId });
    console.log(`  -> téléphone inscrit aux notifications pour ${req.phone}`);
    return res.status(204).end();
  });
}

// Prévient les téléphones du client que son transfert a changé de statut.
async function notifyStatusChange(transfer) {
  const fids = [...devices]
    .filter(([, device]) => device.phone === transfer.owner && isSessionActive(device.sessionId))
    .map(([fid]) => fid);
  if (fids.length === 0) return console.log('  -> aucun téléphone inscrit : pas de notification');

  const auth = getAuth();
  if (!auth) return console.log('  -> service-account.json absent : notification non envoyée');
  const projectId = await auth.getProjectId();
  const client = await auth.getClient();

  for (const fid of fids) {
    try {
      await client.request({
        url: `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        method: 'POST',
        data: {
          message: {
            fid, // cible actuelle de l'API v1 (le champ `token` est déprécié)
            notification: {
              title: TITLES[transfer.status] || 'Transfert mis à jour',
              body: 'Touchez pour voir le détail.',
            },
            // La clé d'idempotence : c'est elle qui identifie le transfert dans l'app.
            data: { transferKey: transfer.idempotencyKey, status: transfer.status },
            android: { priority: 'HIGH' },
          },
        },
      });
      console.log(`  -> notification FCM envoyée (${transfer.status})`);
    } catch (e) {
      const status = e.response && e.response.status;
      // 404 UNREGISTERED ou 400 INVALID_ARGUMENT : identifiant périmé ou faux
      // (app désinstallée, désinscrite) : on l'oublie, comme le recommande FCM.
      if (status === 404 || status === 400) devices.delete(fid);
      const detail = e.response?.data?.error?.status || e.message;
      console.log(`  -> échec de l'envoi FCM (${status} ${detail})`);
    }
  }
}

function resetDevices() {
  devices.clear();
}

module.exports = { registerPushRoutes, notifyStatusChange, resetDevices };
