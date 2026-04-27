module EspaceCliente
  # ============================================================
  # Rendez-vous à venir — liste des réservations futures
  # ============================================================
  class RdvsController < BaseController
    # GET /espace-cliente/rdvs — liste tous les RDV à venir (confirmés ou en attente)
    def index
      # On charge les réservations futures (aujourd'hui inclus), triées chronologiquement
      # includes(:prestation) évite les N+1 queries lors de l'affichage du nom du soin
      @rdvs = current_user.bookings
                          .where(statut: ['confirme', 'en_attente'])
                          .where('date >= ?', Date.today)
                          .order(date: :asc, heure: :asc)
                          .includes(:prestation)
    end
  end
end
