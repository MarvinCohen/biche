module Admin
  # ============================================================
  # Horaires d'ouverture — édition d'un jour de la semaine
  #
  # La liste des 7 jours est servie par `Admin::DisponibilitesController#index`.
  # Ce controller ne gère plus que l'action `update` (un jour à la fois).
  # ============================================================
  class BusinessHoursController < BaseController

    # PATCH /admin/business_hours/:id — sauvegarde un jour
    # Le formulaire envoie un PATCH par jour : c'est plus simple
    # qu'un gros formulaire global, et ça donne un feedback immédiat
    # (notice "Lundi enregistré.").
    def update
      @business_hour = BusinessHour.find(params[:id])

      if @business_hour.update(business_hour_params)
        redirect_to admin_disponibilites_path,
                    notice: "#{@business_hour.nom_jour} enregistré."
      else
        # En cas d'erreur de validation, on recharge la page Disponibilités complète,
        # MAIS on remplace la ligne en cours d'édition par `@business_hour` (qui porte
        # les erreurs) — sinon la vue afficherait la version sans erreurs lue depuis
        # la base et le user ne verrait jamais le message d'échec.
        @business_hours = BusinessHour.triee_lundi_premier.map do |bh|
          bh.id == @business_hour.id ? @business_hour : bh
        end
        @indisponibilites        = Indisponibilite.a_venir
        @nouvelle_indisponibilite = Indisponibilite.new(date_debut: Date.today, date_fin: Date.today)
        flash.now[:alert] = "Erreur sur #{@business_hour.nom_jour} — voir les détails sous le formulaire."
        render "admin/disponibilites/index", status: :unprocessable_entity
      end
    end

    private

    # Champs autorisés depuis le formulaire admin
    def business_hour_params
      params.require(:business_hour).permit(
        :ouvert,
        :heure_debut,
        :heure_fin,
        :pause_debut,
        :pause_fin,
        :pas_minutes
      )
    end
  end
end
