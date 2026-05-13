module EspaceCliente
  # ============================================================
  # Crédits de remplissage — page dédiée à la consultation des crédits
  # de pack achetés par la cliente.
  #
  # Une cliente a 2 catégories de crédits :
  # - Actifs : nb_restant > 0 ET date_expiration >= aujourd'hui → utilisables
  # - Historique : épuisés ou expirés → affichés pour traçabilité
  # ============================================================
  class CreditsController < BaseController
    # GET /espace_cliente/credits — affiche les crédits actifs + l'historique
    def index
      # Crédits encore utilisables (nb_restant > 0 ET non expirés), triés par
      # expiration la plus proche (FIFO — pour que la cliente voie ce qui expire bientôt).
      # `includes(:prestation)` évite les N+1 (on affiche le nom de la pose pour chacun).
      @credits_actifs = current_user.credits
                                    .actifs
                                    .par_expiration_proche
                                    .includes(:prestation)

      # Historique : crédits dont il ne reste plus rien OU qui sont expirés.
      # Affichés en bas de page, plus discrètement (passé).
      # On les trie par date d'expiration descendante (les plus récents en premier).
      @credits_historique = current_user.credits
                                        .where('nb_restant <= 0 OR date_expiration < ?', Date.today)
                                        .order(date_expiration: :desc)
                                        .includes(:prestation)
    end
  end
end
