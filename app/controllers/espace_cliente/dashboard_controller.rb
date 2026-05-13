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
      # ---- Onglet "Mes RDV" : tous les rendez-vous à venir ----
      # On garde @prochain_rdv pour le bloc stats en haut (avatar)
      @prochain_rdv  = current_user.prochain_rdv
      # Liste complète pour l'onglet "Mes RDV" (confirmés + en attente, date future)
      @rdvs_a_venir = current_user.bookings
                                   .where(statut: ['confirme', 'en_attente'])
                                   .where('date >= ?', Date.today)
                                   .order(date: :asc, heure: :asc)
                                   .includes(:prestation)

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

      # ---- Crédits de remplissage actifs : utilisés dans le hero (nombre)
      # et la mini-section de l'onglet Fidélité (preview + CTA vers /espace_cliente/credits).
      # On limite à 3 dans la preview, on affiche le total et un lien "Voir tout".
      @credits_actifs_preview = current_user.credits_actifs.includes(:prestation).limit(3)
      @credits_actifs_count   = current_user.credits_actifs.count
    end

  end
end
