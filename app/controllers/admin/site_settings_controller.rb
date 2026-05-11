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
      # On lit chaque clé qu'on veut afficher dans le formulaire.
      # Si la clé n'existe pas encore, `get` renvoie nil → champ vide.
      @tiktok_latest_url = SiteSetting.get("tiktok_latest_url")
    end

    # PATCH /admin/site_settings
    # Reçoit les valeurs depuis le formulaire et les enregistre.
    def update
      # On strip pour enlever espaces accidentels en début/fin (copier-coller).
      url = params.dig(:site_settings, :tiktok_latest_url).to_s.strip

      # `set` fait un find_or_initialize_by + save → un seul enregistrement
      # par clé, créé si besoin, mis à jour sinon.
      SiteSetting.set("tiktok_latest_url", url)

      redirect_to edit_admin_site_settings_path, notice: "Réglages enregistrés."
    end
  end
end
