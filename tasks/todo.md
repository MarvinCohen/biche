# Plan — Version Desktop de Biche. ✅ TERMINÉ

## Objectif
Adapter l'app Biche. (mobile-first) pour offrir une vraie expérience desktop sur tablette et grand écran, sans casser le mobile.

## Approche retenue : Fichier `desktop.css` unique
Au lieu d'éparpiller les media queries dans chaque fichier CSS, on a créé **un seul fichier `desktop.css`** qui regroupe TOUTES les règles responsive ≥768px et ≥1024px.

**Pourquoi ce choix** :
- ✅ Tout le desktop dans un seul endroit (facile à comprendre/désactiver)
- ✅ Aucune modification des CSS mobiles existants → zéro risque de régression
- ✅ Importé en dernier dans `app.css` → la cascade fait écraser les règles mobiles uniquement sur grand écran

## Breakpoints utilisés
- **< 768px** → expérience mobile actuelle (intacte, mockup phone conservé)
- **≥ 768px** → tablette : mockup retiré, layouts 2 colonnes
- **≥ 1024px** → desktop : nav horizontale fixe, sidebars, grilles 3-4 col

## Fichiers modifiés (3 seulement)
- ✅ `app/assets/stylesheets/desktop.css` — **NOUVEAU** (~870 lignes, toutes les règles desktop)
- ✅ `app/assets/stylesheets/app.css` — ajout d'1 ligne `@import "desktop.css"` en fin
- ✅ `app/views/layouts/application.html.erb` — ajout de la `<nav class="nav-desktop">` (cachée < 1024px)

## Étapes effectuées

### 🧱 Phase 1 — Fondations (layout global)
- [x] Neutralisation du `.phone` (border-radius, shadow, max-width) à ≥768px
- [x] Body fond clair, padding 0
- [x] Wrap élargi à 100% (la nav-desktop centre son contenu en interne)
- [x] Nav desktop horizontale fixe à ≥1024px (cachée < 1024px)
- [x] Burger caché à ≥1024px
- [x] Footer multi-colonnes (gap 32px, padding 60px)
- [x] Titres `.s-h2` agrandis (28→42px), sous-titres `.s-sub` aérés
- [x] Flash messages déplacés en haut de page

### 🏠 Phase 2 — Homepage
- [x] Hero 50/50 (photo 320px à gauche, texte à droite)
- [x] Hero h1 38→64px, big-B 320→480px
- [x] Carousel prestations → grille 4 colonnes
- [x] Shop carousel → grille 3 colonnes
- [x] Map embed agrandie (200→320px)
- [x] Section accessibilité centrée max 800px

### 📋 Phase 3 — Prestations
- [x] Header de page agrandi (h1 42→64px)
- [x] Pills filtre catégories centrées et flex-wrap
- [x] Liste tarifs `.full-list` centrée max 800px
- [x] Tableau retouches centré
- [x] Bloc info morphologie centré max 600px

### 📅 Phase 4 — Réservation
- [x] Steps-bar agrandie (cercles 32→40px)
- [x] Sections d'étape centrées max 700px
- [x] Sélection prestation : grille 2 colonnes
- [x] Calendrier max 380px
- [x] Récap + total agrandis (26→32px)
- [x] Pages success / show centrées max 700px

### 👤 Phase 5 — Espace cliente
- [x] Profile-hero agrandi (avatar 72→96px, name 26→36px)
- [x] Stats du profil sur max 600px
- [x] Client-nav onglets centrés max 1200px
- [x] Carte fidélité centrée max 600px
- [x] **Stats fidélité : grille 4 colonnes** (au lieu de 2x2)
- [x] **Détails techniques historique : grille 4 colonnes**
- [x] Newsletters / settings centrés

### 🔐 Phase 6 — Admin Syam
- [x] Nav admin agrandie (logo 18→22px)
- [x] Header admin agrandi (titre 24→32px)
- [x] **Stats : grille 4 colonnes** (au lieu de 2x2)
- [x] **Tuiles navigation : 4 colonnes ≥768px, 5 colonnes ≥1024px**
- [x] Cartes RDV pleine largeur (heure 48→60px)
- [x] Boutons d'action en ligne (au lieu d'empilés)
- [x] Nav-desktop globale masquée sur pages admin (via `:has()`)

### 📄 Phase 7 — Pages statiques
- [x] **About** : portrait + nom côte à côte, valeurs grille 4 col, studio 4 col
- [x] **FAQ** : grille 2 colonnes
- [x] **Contact** : quick-links agrandis, form-inputs aérés
- [x] **Avis** : grille 2 colonnes pour les avis, rating 96px
- [x] **Galerie** : collage agrandi, masonry 4 colonnes, vidéos 4 col, Instagram 6 col
- [x] **Morphologie** : techniques 4 colonnes, eye-grid 3 col, reco-grid 4 col
- [x] **Shop** : packs 3 col, produits 4 col, gift-card max 600px
- [x] **Auth Devise** : inputs agrandis (14→16px font)

### ✅ Phase 8 — Vérifications cohérence
- [x] Toutes les règles desktop sont dans `@media (min-width: 768px)` ou `(min-width: 1024px)` → mobile intact
- [x] La nav-desktop est cachée par défaut (`display: none`), visible uniquement ≥1024px
- [x] Le burger reste actif sur mobile et tablette (<1024px)
- [x] Sur les pages admin, la nav-desktop est masquée pour éviter double-nav
- [x] Les pages auth Devise utilisent les classes `.auth-*` agrandies en desktop

## À tester en navigateur
- [ ] Résolution 375px (iPhone) → mockup phone conservé
- [ ] Résolution 768px (iPad) → mockup retiré, layouts 2 col
- [ ] Résolution 1440px (laptop) → nav horizontale, layouts 3-4 col
- [ ] Vérifier que le burger fonctionne toujours sur mobile
- [ ] Vérifier le focus des liens nav-desktop au clavier (accessibilité)

## Notes pour la suite
- Si tu veux revenir au mobile partout pour tester, commente la ligne `@import "desktop.css"` dans `app.css`
- Si une page desktop ne te plaît pas, tu peux modifier juste sa section dans `desktop.css` (chaque phase est commentée)
- Le `:has()` est supporté sur Chrome 105+, Safari 15.4+, Firefox 121+ → safe en 2026

## Mémoire de session
- 7 phases CSS faites en 1 seul fichier `desktop.css` (~870 lignes)
- 1 modif au layout (nav-desktop)
- 1 modif à app.css (import)
- En attente : retours de Syam sur Railway pour le déploiement
