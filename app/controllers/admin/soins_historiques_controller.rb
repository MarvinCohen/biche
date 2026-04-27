module Admin
  # ============================================================
  # Fiches soins — Syam remplit la fiche technique après chaque prestation
  # ============================================================
  class SoinsHistoriquesController < BaseController
    before_action :set_booking, only: [:new, :create]
    before_action :set_soin_historique, only: [:edit, :update]

    # GET /admin/soins_historiques/new?booking_id=X — formulaire de création
    def new
      # On initialise une fiche vide liée au booking
      @soin_historique = @booking.build_soin_historique
    end

    # POST /admin/soins_historiques — sauvegarde la fiche
    def create
      @soin_historique = @booking.build_soin_historique(soin_params)

      if @soin_historique.save
        redirect_to admin_booking_path(@booking),
                    notice: "Fiche technique enregistrée."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/soins_historiques/:id/edit — modification de la fiche
    def edit
      # @soin_historique est chargé par set_soin_historique
      @booking = @soin_historique.booking
    end

    # PATCH /admin/soins_historiques/:id — sauvegarde les modifications
    def update
      @booking = @soin_historique.booking

      if @soin_historique.update(soin_params)
        redirect_to admin_booking_path(@booking),
                    notice: "Fiche technique mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Charge le booking depuis params[:booking_id]
    # Fonctionne pour new (query param dans l'URL) ET pour create (hidden field dans le form)
    def set_booking
      booking_id = params[:booking_id] || params.dig(:soin_historique, :booking_id)
      @booking = Booking.find(booking_id)
    end

    # Charge la fiche soin depuis params[:id] (pour edit/update)
    def set_soin_historique
      @soin_historique = SoinHistorique.find(params[:id])
    end

    # Champs autorisés pour la fiche technique
    def soin_params
      params.require(:soin_historique).permit(
        :courbure,    # ex: "C classique", "D curl"
        :longueur,    # ex: "11-13mm"
        :epaisseur,   # ex: "0.07mm", "0.10mm"
        :technique,   # ex: "Cil à cil", "Volume 2D"
        :note_syam    # note personnalisée (texture des cils, réaction, recommandations)
      )
    end
  end
end
