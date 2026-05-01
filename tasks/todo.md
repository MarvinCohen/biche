## Objectif
Rendre la page admin de Syam plus visuelle :
- **Option A** : transformer la navigation en grille d'icônes (2 colonnes, emojis + labels)
- **Option C** : enrichir les stats avec le CA du jour et le CA du mois

## Fichiers impactés
- `app/controllers/admin/dashboard_controller.rb` — ajouter @ca_jour et @ca_mois
- `app/views/admin/dashboard/index.html.erb` — refaire la section stats + section navigation
- `app/assets/stylesheets/admin.css` — ajouter les styles grid navigation + stats enrichies

## Étapes

### Option C — Stats enrichies
- [x] Dans le controller : ajouter `@ca_jour` (sum prix_cents des bookings confirmés/terminés aujourd'hui)
- [x] Dans le controller : ajouter `@ca_mois` (sum prix_cents des bookings confirmés/terminés ce mois)
- [x] Dans la vue : passer de 3 stats (grille 3 col) à 4 stats (grille 2x2)
      - Ligne 1 : RDV aujourd'hui + CA du jour
      - Ligne 2 : RDV ce mois + CA du mois
- [x] Dans le CSS : adapter `.admin-stats` en `grid-template-columns: 1fr 1fr` sur 2 lignes

### Option A — Grid d'icônes navigation
- [x] Dans la vue : remplacer les 9 boutons `.btn-admin-fiche` par une grille de tuiles
- [x] Dans le CSS : ajouter `.admin-nav-grid` (display grid 2 col, gap 8px)
- [x] Dans le CSS : ajouter `.admin-nav-tile` (fond blanc, border, border-radius 16px, centré)
- [x] Dans le CSS : ajouter `.admin-nav-tile-icon` (font-size 26px, display block)
- [x] Dans le CSS : ajouter `.admin-nav-tile-label` (font-size 9px, uppercase, letter-spacing)
- [x] Dans le CSS : ajouter `.admin-nav-tile--primary` pour "Nouveau RDV" (fond sombre, texte blanc)
