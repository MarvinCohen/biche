module EspaceCliente
  # ============================================================
  # Tableau de bord — page principale de l'espace cliente
  # Charge TOUTES les données pour les 5 onglets de la vue :
  # Fidélité / Mes RDV / Historique / Messages / Profil
  # La carte fidélité (@fidelite_card) est chargée par BaseController
  # ============================================================
  class DashboardController < BaseController

    # GET /espace-cliente
    def index
      # ---- Onglet "Mes RDV" : prochain rendez-vous confirmé ----
      @prochain_rdv = current_user.prochain_rdv

      # ---- Onglet "Historique" : tous les soins terminés, du plus récent ----
      # includes évite les N+1 queries (prestation + note de Syam chargées en 1 requête)
      @historique = current_user.bookings
                                .where(statut: 'termine')
                                .order(date: :desc)
                                .includes(:prestation, :soin_historique)

      # ---- Onglet "Messages" : tous les messages de la cliente ----
      @messages = current_user.messages.recents

      # ---- Badge de notifications : nombre de messages non lus ----
      @messages_non_lus_count = current_user.messages.non_lus.count
    end

  end
end
