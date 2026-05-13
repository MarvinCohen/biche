module Admin
  # ============================================================
  # Disponibilités — vue unique regroupant :
  # - les horaires hebdomadaires (BusinessHour, semaine type)
  # - les fermetures exceptionnelles (Indisponibilite, ad-hoc)
  #
  # Les modèles restent distincts (sémantique différente : récurrent
  # vs ponctuel), seule l'UX admin est centralisée ici.
  #
  # Les actions update/create/destroy continuent d'être servies par
  # BusinessHoursController et IndisponibilitesController — elles
  # redirigent simplement vers `admin_disponibilites_path` après
  # succès, au lieu de leurs propres pages d'index.
  # ============================================================
  class DisponibilitesController < BaseController

    # GET /admin/disponibilites — page unique de gestion des dispos
    def index
      # ---- Section 1 : Semaine type ----
      # Les 7 jours, triés lundi → dimanche (convention française)
      @business_hours = BusinessHour.triee_lundi_premier

      # ---- Section 2 : Fermetures exceptionnelles ----
      # Indispos à venir, triées chronologiquement
      @indisponibilites = Indisponibilite.a_venir

      # Instance vierge pour le formulaire "Bloquer une date"
      # Pré-remplie sur aujourd'hui pour éviter un date_debut vide
      @nouvelle_indisponibilite = Indisponibilite.new(
        date_debut: Date.today,
        date_fin:   Date.today
      )
    end
  end
end
