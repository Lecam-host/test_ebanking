// Comptes simulés : chaque client part avec 1 000 000 FCFA.
//
// Le solde ne vit que sur le serveur : c'est lui qui débite, rembourse et
// refuse. L'app n'affiche que le dernier solde connu. Le compte est ouvert au
// premier accès authentifié de ce numéro, et le reste d'une session à l'autre.
const INITIAL_BALANCE = 1000000; // FCFA

const balances = new Map(); // téléphone -> solde en FCFA

function balanceOf(phone) {
  if (!balances.has(phone)) balances.set(phone, INITIAL_BALANCE);
  return balances.get(phone);
}

function debit(phone, amount) {
  balances.set(phone, balanceOf(phone) - amount);
}

function credit(phone, amount) {
  balances.set(phone, balanceOf(phone) + amount);
}

function registerAccountRoutes(app) {
  // --- Administration (démo ; jamais perturbée par le chaos) ---

  // Recrédite un compte à la main pendant les essais. Ce n'est pas une
  // fonction de l'app : le client ne peut pas se faire un dépôt lui-même.
  app.post('/admin/accounts/credit', (req, res) => {
    const { phone, amount } = req.body || {};
    if (!/^\d{10}$/.test(phone ?? '') || !Number.isInteger(amount) || amount <= 0) {
      return res.status(422).json({ error: 'validation_error' });
    }
    credit(phone, amount);
    console.log(`[admin] ${phone} recrédité de ${amount} FCFA`);
    return res.json({ phone, balance: balanceOf(phone) });
  });
}

function resetAccounts() {
  balances.clear();
}

module.exports = { registerAccountRoutes, balanceOf, debit, credit, resetAccounts };
