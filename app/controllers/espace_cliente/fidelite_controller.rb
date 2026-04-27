module EspaceCliente
  # ============================================================
  # Fidélité — page dédiée à la carte fidélité
  # @fidelite_card est déjà chargé par BaseController#set_fidelite_card
  # ============================================================
  class FideliteController < BaseController
    # GET /espace-cliente/fidelite — affiche la carte et les statistiques
    def show
      # @fidelite_card est disponible automatiquement (chargé par BaseController)
      # Pas besoin de requête supplémentaire ici
    end
  end
end
