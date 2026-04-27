# CLAUDE.md — Projet Biche.

## Contexte du projet

Application Rails pour **Syam**, technicienne du regard à Bordeaux.
Elle travaille au **Calao Studio, 37 Rue Lachassaigne, 33000 Bordeaux**.

L'app gère les réservations de soins, un espace cliente, un programme de fidélité, et une boutique en ligne.

---

## Stack technique

- **Ruby on Rails 8.1.3** — template Le Wagon
- **PostgreSQL** — base de données
- **Devise** — authentification clientes
- **Stimulus** — comportements JS (un controller par comportement)
- **CSS vanilla** — pas de Bootstrap, système de variables CSS custom
- **Stripe** — paiements (à intégrer : acompte 30% + boutique)
- **Letter Opener** — emails en dev (actuellement désactivé pour démo)

---

## Architecture des modèles

### `User`
Cliente ou admin (Syam).
- `admin: boolean` — `true` pour Syam uniquement
- `first_name`, `last_name`, `email`, `phone`, `birth_date`
- Associations : `has_many :bookings`, `has_one :fidelite_card`, `has_many :messages`, `has_many :orders`
- Méthodes notables : `prochain_rdv` (inclut statuts `confirme` ET `en_attente`), `nom_complet`

### `Prestation`
Catalogue des soins proposés.
- `nom`, `description`, `categorie`, `prix_cents`, `duree_minutes`, `disponible`
- Catégories : `extensions`, `rehaussement`, `sourcils`
- Scopes : `disponibles`, `par_nom`
- Méthodes : `duree_formatee`, `prix_euros`

### `Booking`
Réservation d'un soin par une cliente.
- `user_id`, `prestation_id`, `date`, `heure`, `statut`, `notes_cliente`
- `acompte_cents`, `stripe_payment_intent_id`, `mode_paiement`
- Statuts : `en_attente` → `confirme` → `termine` / `annule`

### `FideliteCard`
Programme de fidélité — une carte par cliente.
- `user_id`, `points`, `visites`, `recompenses_utilisees`

### `SoinHistorique`
Fiche technique post-soin remplie par Syam.
- `booking_id`, `technique`, `longueur`, `epaisseur`, `courbure`, `note_syam`

### `Product`
Produits de la boutique.
- `nom`, `description`, `type_produit`, `prix_cents`, `actif`
- Types : `carte_cadeau`, `pack`, (autre = produit standard)

### `Order`
Commande boutique.
- `user_id`, `product_id`, `montant_cents`, `statut`, `stripe_payment_intent_id`
- `destinataire_nom`, `destinataire_email` (pour cartes cadeaux)

### `Message`
Newsletters / notifications envoyées par Syam aux clientes.
- `user_id`, `titre`, `contenu`, `type_message`, `lu`

---

## Routes principales

```
GET  /                          pages#home
GET  /prestations               prestations#index
GET  /prestations/:id           prestations#show
GET  /bookings/new              bookings#new
POST /bookings                  bookings#create
GET  /bookings/creneaux         bookings#creneaux  (AJAX)

# Espace cliente (authentification requise)
GET  /espace_cliente            espace_cliente/dashboard#index
GET  /espace_cliente/fidelite   espace_cliente/fidelite#show
GET  /espace_cliente/rdvs       espace_cliente/rdvs#index
GET  /espace_cliente/historique espace_cliente/historique#index
GET  /espace_cliente/messages   espace_cliente/messages#index
GET  /espace_cliente/profil     espace_cliente/profil#show

# Admin (admin: true requis)
GET  /admin                     admin/dashboard#index
GET  /admin/bookings            admin/bookings#index
PATCH /admin/bookings/:id/confirmer
PATCH /admin/bookings/:id/terminer
PATCH /admin/bookings/:id/annuler
GET  /admin/users               admin/users#index

# Shop
GET  /shop                      pages#shop
GET  /orders/new                orders#new
POST /orders                    orders#create

# Stripe
POST /stripe/webhook            stripe#webhook
```

---

## Système de design CSS

### Variables globales (`application.css`)

```css
--color-dark:    #2e2926;   /* Brun foncé — boutons, textes, footer */
--color-nude:    #f7f5f2;   /* Beige nude — fond principal */
--color-cream:   #f6f4f1;   /* Crème légèrement plus sombre */
--color-sand:    #e8e2d8;   /* Sable — hero accueil */
--color-accent:  #b8a898;   /* Beige rosé — accents, étoiles, fidélité */
--color-muted:   #8e8480;   /* Gris chaud — textes secondaires */
--color-border:  #e2dbd2;   /* Bord des cartes */
--color-bg-dark: #241e1c;   /* Fond extérieur sombre */

--font-serif: 'Cormorant Garamond', serif;
--font-sans:  'Jost', sans-serif;
--border-radius-pill: 50px;
--section-padding: 48px 24px;
```

### Classes de sections
```css
.sec           /* background: #fff */
.sec-cream     /* background: var(--color-cream) */
.sec-nude      /* background: var(--color-nude) */
.sec-dark      /* background: var(--color-dark) */
```

### Fichiers CSS par page
- `application.css` — variables, nav, footer, layout global
- `home.css` — hero, carousel prestations, blocs fidélité/shop/localisation
- `pages.css` — pages statiques (about, faq, contact, galerie…)
- `prestations.css` — catalogue soins + accordion tarifs
- `bookings.css` — tunnel de réservation
- `espace_cliente.css` — dashboard, profil, historique
- `admin.css` — interface admin Syam

---

## Pages et vues

### Homepage (`/`)
- Hero avec photo Syam + CTA réservation
- Carousel prestations (4 soins, avec dots dynamiques)
- Bloc fidélité (arche sombre)
- Bloc shop best-sellers (arche sombre, auto-scroll 2.5s)
- Section localisation (Google Maps iframe, blob organique)
- Footer

### Prestations (`/prestations`)
- Pills de filtre par catégorie (extensions, rehaussement, sourcils)
- Carousel horizontal filtrable
- Accordion tarifs groupés par catégorie
- Retouches groupées par nom de base avec variants (2sem / 3sem)

### Réservation (`/bookings/new`)
- Sélection soin (avec pills de filtre)
- Sélection date + créneaux disponibles (AJAX)
- Notes et confirmation

### Espace cliente
- Dashboard : stats (visites, points, prochain RDV), liste des RDVs à venir
- Fidélité : carte avec points et historique
- Historique : soins passés avec fiche technique

### Admin
- Dashboard : planning du jour + stats
- Gestion des réservations (confirmer, terminer, annuler)
- Liste des clientes
- Envoi de messages/newsletters

---

## Points importants

### Mailer désactivé pour la démo
Dans `bookings_controller.rb`, la ligne suivante est commentée :
```ruby
# BookingMailer.confirmation_reservation(@booking).deliver_later
```
À réactiver quand l'SMTP de production sera configuré.

### Ngrok (tests avec cliente)
Dans `config/environments/development.rb` :
```ruby
config.hosts << /.*\.ngrok-free\.(app|dev)/
```

### Stripe (à intégrer)
- Acompte 30% à la réservation
- Paiement complet pour les commandes boutique
- Webhook configuré sur `POST /stripe/webhook`
- Les colonnes `stripe_payment_intent_id` et `acompte_cents` existent déjà en base

### Programme fidélité
- 1 visite = 1 point
- Logique de calcul à définir avec Syam
- La `FideliteCard` est créée automatiquement à l'inscription (à vérifier dans le modèle User)

---

## Tâches en attente

- [ ] Intégration Stripe (acompte 30% booking + paiement boutique)
- [ ] Configuration SMTP production (email de confirmation)
- [ ] Réactiver `BookingMailer.confirmation_reservation`
- [ ] Harmonisation des couleurs entre toutes les pages
- [ ] Page admin : formulaire fiches techniques post-soin
- [ ] Page espace_cliente/historique : afficher les fiches techniques
- [ ] Déploiement production (Heroku / Render)
