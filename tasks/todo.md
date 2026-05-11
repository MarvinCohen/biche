# Plan — Embed dernière vidéo TikTok (home + galerie)

## Objectif
Afficher la dernière vidéo TikTok de Syam (compte `@atelier_b.iche`) sur la home ET la galerie,
via l'embed officiel TikTok. Syam met à jour l'URL depuis son admin quand elle poste une nouvelle vidéo.

## Choix techniques
- **Stockage** : un seul modèle générique `SiteSetting` (key/value) — extensible pour de futurs réglages
- **Embed** : `<blockquote class="tiktok-embed">` + `https://www.tiktok.com/embed.js` (officiel)
- **Admin** : nouvelle vue `admin/site_settings#edit` pour modifier l'URL

## Fichiers impactés

### Backend (modèle + migration)
- `db/migrate/XXXX_create_site_settings.rb` — table `site_settings(key:string unique, value:text)`
- `app/models/site_setting.rb` — méthode helper `SiteSetting.get(key)` / `.set(key, value)`
- `db/seeds.rb` — seed `tiktok_latest_url` (vide au départ)

### Admin
- `config/routes.rb` — ajouter `resource :site_settings, only: %i[edit update]` dans le namespace admin
- `app/controllers/admin/site_settings_controller.rb` — actions `edit` / `update`
- `app/views/admin/site_settings/edit.html.erb` — formulaire simple (1 champ URL)
- `app/views/admin/dashboard/index.html.erb` — ajouter un lien "Réglages du site"

### Vues publiques
- `app/views/shared/_tiktok_embed.html.erb` — partial réutilisable (affiche l'embed si URL présente, sinon rien)
- `app/views/pages/home.html.erb` — render du partial dans une nouvelle section
- `app/views/pages/galerie.html.erb` — render du partial juste avant le bloc Instagram
- `app/controllers/pages_controller.rb` — charger `@tiktok_url` dans `home` et `galerie`

### CSS
- `app/assets/stylesheets/pages.css` — styles section TikTok galerie (titre, conteneur)
- `app/assets/stylesheets/home.css` — styles section TikTok home

## Étapes
- [ ] Générer migration `site_settings` (key, value, timestamps + index unique sur key)
- [ ] Créer modèle `SiteSetting` avec helpers `.get(key)` / `.set(key, value)`
- [ ] Ajouter seed `tiktok_latest_url` (chaîne vide par défaut)
- [ ] `rails db:migrate db:seed` en local
- [ ] Ajouter route admin `resource :site_settings, only: %i[edit update]`
- [ ] Créer `Admin::SiteSettingsController` avec `edit` + `update` (params permit `tiktok_latest_url`)
- [ ] Créer la vue `admin/site_settings/edit.html.erb` (1 input URL + bouton enregistrer)
- [ ] Ajouter un lien "Réglages du site" dans le dashboard admin
- [ ] Créer partial `shared/_tiktok_embed.html.erb` — affiche le blockquote + charge le script
- [ ] Charger `@tiktok_url = SiteSetting.get("tiktok_latest_url")` dans `PagesController#home` et `#galerie`
- [ ] Insérer le partial dans `home.html.erb` (à placer entre quelles sections — à confirmer)
- [ ] Insérer le partial dans `galerie.html.erb` juste avant la section Instagram
- [ ] Styliser la section TikTok (titre type "Dernière vidéo", conteneur centré)
- [ ] Tester en local : sans URL → rien ne s'affiche / avec URL valide → embed visible
- [ ] Tester depuis l'admin : modifier l'URL → l'embed change sur les 2 pages

## Question avant de démarrer
**Sur la home, à quel endroit insérer la section TikTok ?**
Options possibles :
- (a) Juste après le hero (très visible)
- (b) Entre le carousel prestations et le bloc fidélité
- (c) Entre le bloc shop et la section localisation
- (d) Juste avant le footer

## Notes
- L'embed TikTok charge un iframe qui peut être lourd → on ne le rend QUE si `@tiktok_url` est présente
- Le script `embed.js` n'est chargé qu'une fois (le partial inclut un `content_for :head` ou un check)
- L'URL TikTok doit être au format `https://www.tiktok.com/@compte/video/123456789` (pas le lien court)
- Pas de validation regex stricte côté modèle pour rester souple — on fait confiance à Syam
