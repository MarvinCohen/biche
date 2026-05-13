module Admin
  # ============================================================
  # Indisponibilités — Syam peut bloquer des créneaux
  # Ex: pause déjeuner, congé, fermeture, formation, etc.
  # Ces plages sont exclues du calcul des créneaux disponibles.
  #
  # La liste et le formulaire de création sont servis par
  # `Admin::DisponibilitesController#index` (vue centralisée).
  # Ce controller ne gère plus que les actions create/destroy.
  # ============================================================
  class IndisponibilitesController < BaseController

    # POST /admin/indisponibilites — créer un blocage
    def create
      @indisponibilite = Indisponibilite.new(indisponibilite_params)

      if @indisponibilite.save
        redirect_to admin_disponibilites_path,
                    notice: "Date bloquée : #{libelle_blocage(@indisponibilite)}."
      else
        # En cas d'échec, on recharge la page Disponibilités complète
        # en injectant l'instance en erreur pour afficher les messages.
        @business_hours          = BusinessHour.triee_lundi_premier
        @indisponibilites        = Indisponibilite.a_venir
        @nouvelle_indisponibilite = @indisponibilite
        render "admin/disponibilites/index", status: :unprocessable_entity
      end
    end

    # DELETE /admin/indisponibilites/:id — supprimer un blocage
    def destroy
      @indisponibilite = Indisponibilite.find(params[:id])
      @indisponibilite.destroy
      redirect_to admin_disponibilites_path, notice: "Date débloquée."
    end

    private

    # Champs autorisés pour la création d'une indisponibilité
    def indisponibilite_params
      params.require(:indisponibilite).permit(:date_debut, :date_fin, :heure_debut, :heure_fin, :raison)
    end

    # Petit helper de libellé pour la notice flash
    # ("Toute la journée" si convention 00:00 → 23:59, sinon plage horaire)
    def libelle_blocage(indispo)
      horaire = indispo.jour_entier? ? "toute la journée" : indispo.plage_horaire
      "#{horaire} · #{indispo.plage_dates}"
    end
  end
end
