# Guide de déploiement — Biche. sur Railway

Guide pas à pas pour déployer l'app Rails 8 de Biche. sur le compte Railway de Syam.

---

## Pré-requis

- ✅ Syam a un compte Railway créé
- ✅ Le code est sur GitHub (sinon : `git push` d'abord sur le repo `MarvinCohen/biche`)
- ✅ Le `Dockerfile` existe à la racine du projet (généré par défaut par Rails 8)
- ✅ Un fichier `config/master.key` existe localement (NE JAMAIS le commit, il est dans `.gitignore`)

---

## Étape 1 — Préparer la `master.key`

Railway a besoin de la `RAILS_MASTER_KEY` pour décrypter les credentials Rails (clés Stripe, etc.).

```bash
# Récupérer la valeur de la master key
cat config/master.key
```

**Copie cette valeur** (chaîne hex de ~32 caractères). On la collera dans Railway à l'étape 4.

---

## Étape 2 — Créer le projet Railway

1. Connecte-toi sur [railway.com](https://railway.com) avec le compte de Syam
2. Clique sur **"New Project"**
3. Choisis **"Deploy from GitHub repo"**
4. Si Railway n'a pas accès à ton repo : autorise l'app GitHub Railway
   - Tu pourras choisir de donner accès uniquement à `MarvinCohen/biche`
5. Sélectionne le repo `biche`
6. Railway détecte automatiquement le `Dockerfile` et lance un premier build (qui va échouer — normal, on n'a pas encore la BDD ni les variables d'env)

---

## Étape 3 — Ajouter PostgreSQL

1. Dans le projet Railway, clique sur **"+ Create"** ou **"+ New"** dans le canvas
2. Choisis **"Database" → "Add PostgreSQL"**
3. Railway provisionne une base PostgreSQL et génère automatiquement la variable `DATABASE_URL`
4. **Lier la BDD à l'app** : clique sur le service "biche" → onglet **Variables** → vérifie que `DATABASE_URL` est bien injectée. Sinon, clique sur **"+ Add Reference"** et sélectionne `Postgres.DATABASE_URL`

---

## Étape 4 — Variables d'environnement

Toujours dans le service "biche" → onglet **Variables**, ajoute :

| Variable | Valeur |
|---|---|
| `RAILS_MASTER_KEY` | la valeur de `cat config/master.key` (étape 1) |
| `RAILS_ENV` | `production` |
| `RAILS_LOG_TO_STDOUT` | `true` |
| `RAILS_SERVE_STATIC_FILES` | `true` |

**Remarque** : `DATABASE_URL` est déjà injectée par Railway (étape 3), pas besoin de la rajouter manuellement.

**Pour Stripe (plus tard)** : tu rajouteras `STRIPE_SECRET_KEY` et `STRIPE_PUBLISHABLE_KEY` quand tu intègreras le paiement.

---

## Étape 5 — Configurer le hôte autorisé

Rails 8 bloque les requêtes venant de hôtes inconnus en production. Il faut autoriser le domaine Railway.

Édite `config/environments/production.rb` (vérifie d'abord si ce n'est pas déjà fait) :

```ruby
# Autorise les requêtes venant du domaine Railway
config.hosts << /.*\.up\.railway\.app/
config.hosts << /.*\.railway\.app/

# Si plus tard tu mets un domaine custom, ajoute-le aussi :
# config.hosts << "biche.fr"
# config.hosts << "www.biche.fr"
```

Puis commit + push :

```bash
git add config/environments/production.rb
git commit -m "Autorise les hôtes Railway en production"
git push
```

Railway redéploiera automatiquement à chaque push sur `main`.

---

## Étape 6 — Lancer les migrations

Le `Dockerfile` Rails 8 par défaut **ne lance PAS les migrations automatiquement**. Il faut les exécuter au premier déploiement.

**Option A — Via la CLI Railway** (recommandé) :

```bash
# Installer Railway CLI (une seule fois)
brew install railway

# Se connecter (ouvre un navigateur)
railway login

# Lier le repo local au projet Railway
railway link

# Lancer les migrations dans le conteneur de prod
railway run rails db:migrate

# (Optionnel) Charger les seeds
railway run rails db:seed
```

**Option B — Via l'interface Railway** :

1. Service "biche" → onglet **Settings**
2. Section **Deploy** → **Custom Start Command** :
   ```
   ./bin/rails db:prepare && ./bin/rails server
   ```
3. Sauvegarde et redéploie

⚠️ Avec l'option B, `db:prepare` tourne à chaque déploiement (idempotent, pas de souci).

---

## Étape 7 — Générer le domaine public

1. Dans le service "biche" → onglet **Settings**
2. Section **Networking** → **Generate Domain**
3. Railway te donne une URL du type `biche-production-xxxx.up.railway.app`
4. Ouvre cette URL → l'app doit s'afficher 🎉

---

## Étape 8 — Domaine personnalisé (optionnel, plus tard)

Quand Syam aura acheté `biche.fr` :

1. Service "biche" → **Settings** → **Networking** → **Custom Domain**
2. Ajoute `biche.fr` et `www.biche.fr`
3. Railway te donne 2 enregistrements DNS (CNAME) à configurer chez le registrar (OVH, Gandi, etc.)
4. Une fois les DNS propagés (5min à 24h), Railway génère automatiquement un certificat SSL

---

## Étape 9 — Variables Stripe (quand tu intégreras le paiement)

Plus tard, dans **Variables** :

| Variable | Valeur |
|---|---|
| `STRIPE_PUBLISHABLE_KEY` | clé publique Stripe (commence par `pk_live_...`) |
| `STRIPE_SECRET_KEY` | clé secrète Stripe (commence par `sk_live_...`) |
| `STRIPE_WEBHOOK_SECRET` | secret webhook Stripe (`whsec_...`) |

Et configure le webhook Stripe pour pointer vers `https://biche.fr/stripe/webhook`.

---

## Étape 10 — Configuration SMTP (envoi emails de confirmation)

Rappel : le `BookingMailer.confirmation_reservation` est commenté dans `bookings_controller.rb`. À réactiver quand SMTP sera configuré.

Variables à ajouter (exemple avec Brevo / SendGrid / Resend) :

| Variable | Valeur |
|---|---|
| `SMTP_ADDRESS` | ex `smtp.brevo.com` |
| `SMTP_PORT` | `587` |
| `SMTP_DOMAIN` | `biche.fr` |
| `SMTP_USERNAME` | login SMTP du provider |
| `SMTP_PASSWORD` | password SMTP |

Puis dans `config/environments/production.rb` :

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:        ENV["SMTP_ADDRESS"],
  port:           ENV["SMTP_PORT"],
  domain:         ENV["SMTP_DOMAIN"],
  user_name:      ENV["SMTP_USERNAME"],
  password:       ENV["SMTP_PASSWORD"],
  authentication: :plain,
  enable_starttls_auto: true
}
config.action_mailer.default_url_options = { host: "biche.fr", protocol: "https" }
```

---

## Inviter Marvin en collaborateur

Pour que tu puisses déployer / debug sans avoir le mot de passe Syam :

1. Syam va dans **Settings** du projet → **Members**
2. **Invite Member** → entrer ton email Railway → rôle **Developer** (peut déployer mais pas facturer)
3. Tu reçois un email d'invitation, tu acceptes → tu vois le projet dans ton dashboard

---

## Checklist de déploiement

- [ ] Code à jour sur GitHub (`git push`)
- [ ] `master.key` récupérée localement
- [ ] Projet Railway créé depuis le repo GitHub
- [ ] PostgreSQL ajouté + `DATABASE_URL` liée
- [ ] Variables `RAILS_MASTER_KEY`, `RAILS_ENV`, `RAILS_LOG_TO_STDOUT`, `RAILS_SERVE_STATIC_FILES` configurées
- [ ] Hôtes Railway autorisés dans `production.rb`
- [ ] Migrations exécutées (`railway run rails db:migrate`)
- [ ] Seeds chargés si besoin
- [ ] Domaine public généré
- [ ] App accessible et fonctionnelle
- [ ] Marvin invité en collaborateur

---

## Coûts estimés

- **Hobby Plan Railway** : 5 $/mois (inclut 5 $ de crédits d'usage)
- **Usage typique pour une petite app Rails + PostgreSQL** : ~5 à 10 $/mois en plus des 5 $ de base
- **Total estimé** : 5 à 15 $/mois selon le trafic

Railway facture **à la consommation** (RAM, CPU, BDD active), donc avec peu de trafic au début, tu resteras sur les 5 $ de base.

---

## En cas de souci

**Build qui échoue** :
- Onglet **Deployments** → cliquer sur le déploiement → voir les logs
- 90% du temps : variable d'env manquante ou Gemfile.lock pas à jour

**App qui plante avec "We're sorry, but something went wrong"** :
- Onglet **Logs** en temps réel sur le service
- Souvent : migration pas lancée ou `RAILS_MASTER_KEY` incorrecte

**Migration foireuse** :
```bash
railway run rails db:migrate:status
railway run rails db:rollback STEP=1
```
