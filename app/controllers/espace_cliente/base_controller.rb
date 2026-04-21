module EspaceCliente
  # ============================================================
  # Controller de base pour l'espace cliente
  # Toutes les pages de l'espace cliente héritent de ce controller.
  # Il garantit que seules les clientes connectées peuvent y accéder.
  # ============================================================
  class BaseController < ApplicationController
    # Devise : redirige vers la page de connexion si non authentifiée
    before_action :authenticate_user!

    # Charge la carte fidélité pour toutes les pages (affichée dans la nav)
    before_action :set_fidelite_card

    private

    # Trouve ou crée la carte fidélité de la cliente connectée
    def set_fidelite_card
      @fidelite_card = current_user.fidelite_card || current_user.create_fidelite_card(
        points: 0, visites: 0, recompenses_utilisees: 0
      )
    end
  end
end
