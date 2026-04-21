module EspaceCliente
  # ============================================================
  # Historique des soins — liste et détail de chaque visite
  # ============================================================
  class HistoriqueController < BaseController
    # GET /espace-cliente/historique — liste de tous les soins passés
    def index
      # Soins terminés, du plus récent au plus ancien
      @soins = current_user.bookings
                           .where(statut: 'termine')
                           .order(date: :desc)
                           .includes(:prestation, :soin_historique)
    end

    # GET /espace-cliente/historique/:id — détail d'un soin avec la note de Syam
    def show
      # On vérifie que la réservation appartient bien à la cliente connectée
      @booking          = current_user.bookings.find(params[:id])
      @soin_historique  = @booking.soin_historique
    end
  end
end
