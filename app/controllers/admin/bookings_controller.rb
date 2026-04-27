module Admin
  # ============================================================
  # Réservations — liste et gestion des statuts
  # ============================================================
  class BookingsController < BaseController
    before_action :set_booking, only: [:show, :confirmer, :terminer, :annuler]

    # GET /admin/bookings — liste de tous les RDV, filtrée par date
    def index
      # Date filtrée (aujourd'hui par défaut)
      @date = params[:date] ? Date.parse(params[:date]) : Date.today

      # Tous les RDV de la date, triés par heure, avec user et prestation préchargés
      @bookings = Booking
                    .where(date: @date)
                    .order(:heure)
                    .includes(:user, :prestation)
    end

    # GET /admin/bookings/:id — détail complet d'un RDV
    def show
      # @booking est chargé par set_booking
      # On charge aussi la fiche soin si elle existe
      @soin_historique = @booking.soin_historique
    end

    # PATCH /admin/bookings/:id/confirmer — passe le statut à "confirme"
    def confirmer
      # On ne confirme que si le RDV est en attente
      if @booking.statut == 'en_attente'
        @booking.update!(statut: 'confirme')

        # Prévenir la cliente par email que son RDV est confirmé
        BookingMailer.rdv_confirme(@booking).deliver_later

        redirect_to admin_booking_path(@booking), notice: "Réservation confirmée. Email envoyé à la cliente."
      else
        redirect_to admin_booking_path(@booking), alert: "Ce RDV ne peut pas être confirmé."
      end
    end

    # PATCH /admin/bookings/:id/terminer — marque le soin comme terminé
    def terminer
      # On ne termine que si le RDV est confirmé
      if @booking.statut == 'confirme'
        @booking.update!(statut: 'termine')

        # Créditer un point fidélité à la cliente (Fat Model : logique dans FideliteCard)
        fidelite = @booking.user.fidelite_card
        fidelite.ajouter_visite! if fidelite

        redirect_to admin_booking_path(@booking),
                    notice: "Soin marqué comme terminé. 1 point fidélité crédité."
      else
        redirect_to admin_booking_path(@booking), alert: "Ce RDV ne peut pas être marqué comme terminé."
      end
    end

    # PATCH /admin/bookings/:id/annuler — annule la réservation
    def annuler
      # On peut annuler n'importe quel RDV non déjà annulé
      unless @booking.statut == 'annule'
        @booking.update!(statut: 'annule')
        redirect_to admin_bookings_path(date: @booking.date), notice: "Réservation annulée."
      else
        redirect_to admin_booking_path(@booking), alert: "Ce RDV est déjà annulé."
      end
    end

    private

    # Charge la réservation — pas de restriction user ici (admin voit tout)
    def set_booking
      @booking = Booking.find(params[:id])
    end
  end
end
