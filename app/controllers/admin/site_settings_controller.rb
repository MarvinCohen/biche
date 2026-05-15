module Admin
  # ============================================================
  # Réglages du site — page unique pour les paramètres globaux
  # éditables par Syam (URL de la dernière vidéo TikTok, etc.)
  #
  # Comme la table `site_settings` est en clé/valeur, on ne suit
  # pas le pattern CRUD habituel (un enregistrement par ressource).
  # Le formulaire édite plusieurs clés à la fois et le controller
  # appelle `SiteSetting.set(...)` pour chacune.
  # ============================================================
  class SiteSettingsController < BaseController

    # GET /admin/site_settings/edit
    # Prépare les valeurs actuelles pour pré-remplir le formulaire.
    def edit
      # Singleton de la vidéo native (clé "video_latest").
      # On expose l'instance complète à la vue pour pouvoir afficher
      # la légende (value) et l'éventuel fichier déjà uploadé.
      @video_setting = SiteSetting.video_setting
    end

    # PATCH /admin/site_settings
    # Reçoit les valeurs depuis le formulaire et les enregistre.
    def update
      # Légende texte de la vidéo (stockée dans `value` du SiteSetting).
      # `to_s.strip` pour gérer le cas nil + enlever espaces accidentels.
      caption = params.dig(:site_settings, :video_caption).to_s.strip

      # Singleton récupéré (ou créé au premier passage).
      video_setting = SiteSetting.video_setting
      video_setting.value = caption

      # Si un nouveau fichier MP4 est uploadé, on l'attache.
      # On ne purge l'ancien que si un nouveau est fourni —
      # sinon on garde celui déjà en place (utile pour modifier
      # juste la légende sans re-uploader).
      if params.dig(:site_settings, :video_file).present?
        video_setting.video_file.attach(params[:site_settings][:video_file])
      end

      # Permet de supprimer la vidéo actuelle via une case à cocher.
      # `==` au lieu de `present?` car "0" est falsy côté form mais
      # truthy en Ruby — on veut explicitement la valeur "1".
      if params.dig(:site_settings, :remove_video) == "1"
        video_setting.video_file.purge
      end

      video_setting.save

      redirect_to edit_admin_site_settings_path, notice: "Réglages enregistrés."
    end
  end
end
