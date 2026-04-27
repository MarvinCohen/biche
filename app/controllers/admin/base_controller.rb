module Admin
  # ============================================================
  # Controller de base — espace admin (Syam uniquement)
  # Tous les controllers admin héritent de celui-ci.
  # Double protection : authentification Devise + flag admin.
  # ============================================================
  class BaseController < ApplicationController
    # Devise : redirige vers login si non connectée
    before_action :authenticate_user!

    # Vérifie que la personne connectée est bien admin (Syam)
    before_action :require_admin!

    private

    # Redirige avec erreur si l'utilisatrice n'est pas admin
    # current_user.admin? renvoie true uniquement si admin = true en base
    def require_admin!
      unless current_user.admin?
        redirect_to root_path, alert: "Accès réservé."
      end
    end
  end
end
