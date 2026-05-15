# Vidéo TikTok native — upload MP4 directement sur le site

## Objectif

Remplacer l'embed TikTok (qui ne lit pas la vidéo au clic — bug TikTok côté serveur, rien à faire) par un **lecteur HTML5 natif** où Syam upload directement le fichier MP4.

Bonus : pas de branding TikTok, autoplay/muted/loop possibles, lecture garantie.

---

## Choix technique

- On garde le modèle `SiteSetting` (clé/valeur) — pas besoin de nouveau modèle.
- On y attache la vidéo via **Active Storage** (`has_one_attached :video_file`).
- On utilise un singleton récupéré par la clé `"video_latest"` pour rattacher l'attachement.
- On garde aussi un champ texte pour le **titre/légende** de la vidéo (ex: "Pose volume 5D").

---

## Fichiers impactés

- `app/models/site_setting.rb` — ajouter `has_one_attached :video_file` + un helper `self.video_setting`
- `app/controllers/admin/site_settings_controller.rb` — accepter le fichier `video_file` + la légende
- `app/views/admin/site_settings/edit.html.erb` — ajouter un `file_field` + champ légende
- `app/controllers/pages_controller.rb` — remplacer `@tiktok_url` par `@latest_video` (instance SiteSetting)
- `app/views/shared/_tiktok_embed.html.erb` — renommer et réécrire en `_video_player.html.erb` (HTML5 `<video>`)
- `app/views/pages/home.html.erb` — appeler le nouveau partial
- `app/views/pages/galerie.html.erb` — appeler le nouveau partial
- `config/routes.rb` — vérifier que les routes admin restent OK (sûrement aucun changement)

---

## Étapes

- [ ] **1.** `SiteSetting` : ajouter `has_one_attached :video_file` + méthode `self.video_setting` qui fait `find_or_create_by(key: "video_latest")` et retourne l'instance.
- [ ] **2.** Controller admin : accepter `params[:site_settings][:video_file]` et `params[:site_settings][:video_caption]`. Strong params + attachement via `.video_file.attach(...)`.
- [ ] **3.** Vue admin : ajouter le `file_field` (accept video/mp4) + champ texte légende. Garder le champ TikTok URL pour transition douce (on pourra le retirer ensuite).
- [ ] **4.** Pages controller : `@latest_video = SiteSetting.video_setting` dans `home` et `galerie` (remplace `@tiktok_url`).
- [ ] **5.** Nouveau partial `_video_player.html.erb` : si `@latest_video.video_file.attached?`, afficher un `<video controls playsinline preload="metadata">` + `<source>` via `url_for(@latest_video.video_file)`. Garder le même design que la section TikTok (titre, tag).
- [ ] **6.** Mettre à jour `home.html.erb` et `galerie.html.erb` pour appeler `render "shared/video_player", video_setting: @latest_video`.
- [ ] **7.** Supprimer l'ancien partial `_tiktok_embed.html.erb` une fois que tout marche.
- [ ] **8.** Test manuel : aller sur /admin/site_settings/edit, uploader un MP4, vérifier que la home affiche et lit la vidéo.

---

## Points d'attention

- **Taille du fichier** : MP4 TikTok = 5-15 Mo généralement, OK pour Active Storage.
- **Format** : `accept="video/mp4"` côté input, et on valide côté modèle (`content_type: ["video/mp4"]`).
- **Storage** : en dev → `storage/`, en prod → à configurer plus tard (S3 / Cloudinary).
- **Lecture mobile iOS** : ajouter `playsinline` sur la balise `<video>` (sinon Safari force le fullscreen au play).
- **Autoplay** : possible seulement si `muted` aussi → on met `muted autoplay loop playsinline` pour un comportement TikTok-like, et `controls` pour que l'utilisateur puisse activer le son.

---

## Question pour toi

OK pour partir là-dessus ? Si tu valides je commence par l'étape 1.
