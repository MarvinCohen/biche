module Admin
  # ============================================================
  # Prestations — CRUD complet
  # Syam peut créer, modifier et supprimer des prestations.
  # ============================================================
  class PrestationsController < BaseController

    before_action :set_prestation, only: [:edit, :update, :destroy]

    # GET /admin/prestations — liste groupée par catégorie
    def index
      # Toutes les prestations (actives et inactives) groupées par catégorie
      # with_attached_photo évite les N+1 queries pour les miniatures
      @prestations_par_categorie = Prestation
                                     .order(:categorie, :nom)
                                     .with_attached_photo
                                     .group_by(&:categorie)
    end

    # GET /admin/prestations/new — formulaire de création
    def new
      @prestation = Prestation.new
      # Disponible par défaut à la création
      @prestation.disponible = true
    end

    # POST /admin/prestations — enregistre la nouvelle prestation
    def create
      @prestation = Prestation.new(prestation_params)

      # Convertir le prix saisi en euros → centimes
      if params[:prestation][:prix_euros].present?
        @prestation.prix_cents = (params[:prestation][:prix_euros].to_f * 100).round
      end

      if @prestation.save
        redirect_to admin_prestations_path,
                    notice: "\"#{@prestation.nom}\" a été ajoutée."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/prestations/:id/edit — formulaire de modification
    def edit
      # @prestation chargée par set_prestation
    end

    # PATCH /admin/prestations/:id — sauvegarde les modifications
    def update
      # Convertir le prix saisi en euros → centimes
      if params[:prestation][:prix_euros].present?
        params[:prestation][:prix_cents] = (params[:prestation].delete(:prix_euros).to_f * 100).round
      end

      if @prestation.update(prestation_params)
        redirect_to admin_prestations_path,
                    notice: "\"#{@prestation.nom}\" mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/prestations/:id — suppression avec protection
    def destroy
      # Le modèle bloque la suppression si des bookings existent (dependent: :restrict_with_error)
      if @prestation.destroy
        redirect_to admin_prestations_path,
                    notice: "\"#{@prestation.nom}\" supprimée."
      else
        # Des RDVs existent pour cette prestation — on ne peut pas supprimer
        redirect_to admin_prestations_path,
                    alert: "Impossible de supprimer \"#{@prestation.nom}\" : des réservations existent. Désactivez-la à la place."
      end
    end

    private

    def set_prestation
      @prestation = Prestation.find(params[:id])
    end

    # Tous les champs modifiables par Syam
    # prix_cents est géré via prix_euros dans les actions create/update
    def prestation_params
      params.require(:prestation).permit(
        :nom, :categorie, :description,
        :prix_cents, :duree_minutes, :disponible,
        :photo  # Fichier image uploadé via Active Storage
      )
    end
  end
end
