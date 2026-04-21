module EspaceCliente
  # ============================================================
  # Tableau de bord — page principale de l'espace cliente
  # Affiche : stats fidélité, prochain RDV, historique récent
  # ============================================================
  class DashboardController < BaseController
    # GET /espace-cliente — vue d'ensemble du compte
    def index
      # Prochain rendez-vous confirmé à venir
      @prochain_rdv = current_user.prochain_rdv

      # Les 3 derniers soins passés pour l'historique rapide
      @historique_recent = current_user.bookings
                                       .where(statut: 'termine')
                                       .where('date < ?', Date.today)
                                       .order(date: :desc)
                                       .limit(3)
                                       .includes(:prestation, :soin_historique)

      # Messages non lus (badge de notification dans la nav)
      @messages_non_lus_count = current_user.messages.non_lus.count
    end
  end
end
