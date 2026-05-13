# Crédits de remplissage — système complet

## Objectif
Permettre à une cliente qui a acheté un pack de remplissages (3 / 6 / 9 sur une pose donnée) d'utiliser ses crédits pour réserver des retouches sans repasser au paiement.

Cycle de vie :
1. Cliente achète un **Pack 6 — Volume léger** (216€)
2. À la création de l'Order → **6 crédits Volume léger** lui sont attribués (valables 6 mois)
3. Elle réserve une **retouche Volume léger 2 ou 3 sem** → option "Utiliser un crédit (5 restants)"
4. Si elle l'utilise → booking créé direct en `confirme`, pas de Stripe, `nb_restant--`
5. Quand Syam marque le RDV "terminé" → l'utilisation est définitive (1 point fidélité crédité comme d'hab)

## Décisions techniques validées
- **Q1** : durée de validité = **nb_remplissages mois** (pack 3 → 3 mois, pack 6 → 6 mois, pack 9 → 9 mois)
- **Q2** : crédit créé **à la création de l'Order** (pré-Stripe). À déplacer dans le webhook Stripe quand on intégrera le paiement réel.
- **Q3** : nouvelle **tuile "Crédits"** dans le dashboard espace cliente (page dédiée)
- **Q4** : sur `/bookings/new`, si crédit applicable → banner avec bouton "Utiliser un crédit (X restants)" — soumet avec `credit_id` et skip Stripe

## Architecture

### Nouveau modèle `Credit`
| Colonne | Type | Détails |
|---|---|---|
| `user_id` | bigint | la cliente propriétaire |
| `order_id` | bigint | l'achat à l'origine (pour historique) |
| `prestation_id` | bigint | la pose (catégorie 'extensions') |
| `nb_total` | integer | 3, 6 ou 9 (copié du pack) |
| `nb_restant` | integer | décrémenté à chaque retouche terminée |
| `date_expiration` | date | calculée à la création |

### Association `Booking → Credit`
- Ajouter `credit_id` (nullable) à `bookings`
- Si `credit_id.present?` : booking payé avec un crédit → pas de Stripe, statut direct `confirme`
- Quand statut passe à `termine` (admin) → décrémenter le crédit

### Matching pose ↔ retouche
Un crédit pour "Volume léger" est applicable à une prestation de catégorie `retouche` dont le **nom contient** "Volume léger" (les retouches s'appellent "Remplissage Volume léger — 2 semaines" etc.).

Méthode `Credit#applicable_a?(prestation)` — basée sur match de nom. Fragile mais suffit tant qu'on respecte la convention de nommage des prestations.

## Fichiers impactés

### Migrations
- `db/migrate/YYYYMMDDHHMMSS_create_credits.rb`
- `db/migrate/YYYYMMDDHHMMSS_add_credit_id_to_bookings.rb`

### Modèles
- `app/models/credit.rb` (nouveau)
- `app/models/user.rb` (`has_many :credits`, helpers `credits_actifs`, `credit_applicable(prestation)`)
- `app/models/order.rb` (callback `after_create :creer_credits_si_pack` ou logique dans controller)
- `app/models/booking.rb` (`belongs_to :credit, optional: true`)

### Controllers
- `app/controllers/orders_controller.rb` (créer le Credit après save si product est un pack)
- `app/controllers/bookings_controller.rb` (permit `:credit_id`, logique de skip Stripe si présent)
- `app/controllers/admin/bookings_controller.rb` (`terminer` → `booking.credit&.utiliser!`)
- `app/controllers/espace_cliente/credits_controller.rb` (nouveau, action `index`)

### Vues
- `app/views/espace_cliente/credits/index.html.erb` (nouveau)
- `app/views/espace_cliente/dashboard/index.html.erb` (ajouter tuile "Crédits")
- `app/views/bookings/new.html.erb` (banner "Utiliser un crédit" + hidden field)
- `app/javascript/controllers/booking_controller.js` (gestion du toggle crédit / paiement)

### Routes
- `config/routes.rb` (ajouter `resources :credits, only: [:index]` dans `namespace :espace_cliente`)

## Étapes

### Données
- [x] 1. Migration `create_credits` (toutes les colonnes ci-dessus + indexes user_id / order_id / prestation_id)
- [x] 2. Migration `add_credit_id_to_bookings` (référence nullable)

### Modèles
- [x] 3. Créer `Credit` avec :
  - validations (presence user/order/prestation, nb_total ∈ [3,6,9], nb_restant >= 0)
  - scopes (`:actifs` = nb_restant > 0 AND date_expiration >= today)
  - méthodes : `applicable_a?(prestation)`, `utiliser!`, `expire?`
- [x] 4. Mettre à jour `User` :
  - `has_many :credits, dependent: :destroy`
  - méthode `credits_actifs`
  - méthode `credit_applicable(prestation)` — retourne le 1er crédit utilisable (FIFO sur date_expiration)
- [x] 5. Mettre à jour `Booking` :
  - `belongs_to :credit, optional: true`
  - méthode `paye_avec_credit?` (= `credit_id.present?`)
- [x] 6. Mettre à jour `Order` : pas de callback, on garde la logique dans le controller (plus visible)

### Création du crédit (achat d'un pack)
- [x] 7. **Flux pack séparé** dans `OrdersController` :
  - Nouvelles routes `get :new_pack` / `post :create_pack` (collection orders)
  - Actions `new_pack` (page de récap) et `create_pack` (Order + Credit en transaction)
  - Vue `orders/new_pack.html.erb`
  - MAJ lien dans `shop.html.erb` → `new_pack_orders_path(product_id: pack.id)`
  - TODO Stripe noté dans le contrôleur — pour la démo, Order créé en `paye` direct

### Réservation avec un crédit
- [x] 8. `BookingsController#new` → charge `@credits_actifs` (avec includes prestation, anti N+1)
- [x] 9. `bookings/new.html.erb` :
  - Hidden field `booking[credit_id]`
  - Option "Utiliser un crédit" en 3e mode de paiement (étape 3), cachée par défaut
  - Sérialisation des crédits en JSON pour le JS via data-value
- [x] 10. Stimulus `booking_controller.js` :
  - `creditsActifsValue` (Array), targets `creditOption`, `creditCount`, `creditIdInput`, `submitBtn`, `confirmNote`, `recapAcompteRow`
  - `refreshCreditOption()` au moment du choix de prestation → matching insensible à la casse sur le nom de pose
  - `selectPayment` remplit `credit_id` quand option crédit choisie, vide sinon
  - `updateRecap` adapte récap + libellé bouton + note selon mode (acompte / empreinte / credit)
- [x] 11. `BookingsController#create` :
  - Permit `:credit_id`
  - Vérification serveur : crédit appartient à current_user, actif, applicable_a? la prestation
  - Si OK : `statut=confirme`, `mode_paiement=credit`, skip Stripe, redirect `@booking`
  - Si KO : flash alert + render :new

### Validation côté admin (consommation effective)
- [x] 12. `Admin::BookingsController#terminer` :
  - Si `@booking.credit` présent → `@booking.credit.utiliser!` (rescue + log si KO)
  - Message flash adapté ("1 remplissage consommé sur le crédit.")

### Espace cliente
- [x] 13. Route `resources :credits, only: [:index]` dans `namespace :espace_cliente`
- [x] 14. `EspaceCliente::CreditsController#index` :
  - `@credits_actifs` (FIFO sur expiration) + `@credits_historique` (épuisés OU expirés)
- [x] 15. Vue `espace_cliente/credits/index.html.erb` :
  - Section "Crédits actifs" — cards avec pose, compteur nb_restant/nb_total, barre de progression, date expiration, CTA Réserver
  - Section "Historique" — opacité réduite, badge Épuisé/Expiré
  - État vide → CTA "Voir les packs" → shop
- [x] 16. Dashboard espace cliente :
  - `@credits_actifs_preview` (3 max) + `@credits_actifs_count` chargés dans le controller
  - Bloc "Mes crédits" affiché dans l'onglet Fidélité si > 0
  - CTA "Voir tous mes crédits →" vers `/espace_cliente/credits`

### Tests manuels
- [ ] 17. Acheter un pack via `/orders/new` → vérifier qu'un Credit apparaît dans `/espace_cliente/credits`
- [ ] 18. Aller sur `/bookings/new`, choisir une retouche correspondante → banner s'affiche
- [ ] 19. Cliquer "Utiliser un crédit" → réserver → booking créé en `confirme` sans Stripe, crédit toujours actif (nb_restant inchangé tant que pas `termine`)
- [ ] 20. Dans admin → marquer le RDV "terminé" → vérifier que `nb_restant` a été décrémenté

## Hors scope (autres tâches)
- Intégration Stripe : déplacement de la création du Credit dans le webhook quand Stripe sera prêt
- Gestion des remboursements (si la cliente annule un RDV payé avec un crédit → restaurer `nb_restant`)
- Email à la cliente quand un crédit va expirer (J-30, J-7)
