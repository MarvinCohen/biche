module Admin
  # ============================================================
  # Indisponibilités — Syam peut bloquer des créneaux
  # Ex: pause déjeuner, congé, fermeture, formation, etc.
  # Ces plages sont exclues du calcul des créneaux disponibles.
  # ============================================================
  class IndisponibilitesController < BaseController

    # GET /admin/indisponibilites — liste des créneaux bloqués à venir
    def index
      # On affiche uniquement les indisponibilités futures et en cours
      @indisponibilites = Indisponibilite.a_venir
    end

    # GET /admin/indisponibilites/new — formulaire de blocage
    def new
      @indisponibilite = Indisponibilite.new
      # Pré-remplir la date de début si passée en paramètre (ex: depuis l'agenda)
      @indisponibilite.date_debut = params[:date] ? Date.parse(params[:date]) : Date.today
      @indisponibilite.date_fin   = @indisponibilite.date_debut
    end

    # POST /admin/indisponibilites — créer un blocage
    def create
      @indisponibilite = Indisponibilite.new(indisponibilite_params)

      if @indisponibilite.save
        redirect_to admin_indisponibilites_path,
                    notice: "Créneau bloqué : #{@indisponibilite.plage_horaire} · #{@indisponibilite.plage_dates}."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # DELETE /admin/indisponibilites/:id — supprimer un blocage
    def destroy
      @indisponibilite = Indisponibilite.find(params[:id])
      @indisponibilite.destroy
      redirect_to admin_indisponibilites_path,
                  notice: "Créneau débloqué."
    end

    private

    # Champs autorisés pour la création d'une indisponibilité
    def indisponibilite_params
      params.require(:indisponibilite).permit(:date_debut, :date_fin, :heure_debut, :heure_fin, :raison)
    end
  end
end
