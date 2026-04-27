module Admin
  # ============================================================
  # Dashboard admin — planning du jour + statistiques globales
  # ============================================================
  class DashboardController < BaseController

    # GET /admin — page principale de l'admin
    def index
      # ---- Date affichée (aujourd'hui par défaut, ou date passée en paramètre) ----
      # params[:date] permet de naviguer d'un jour à l'autre via les flèches
      @date = params[:date] ? Date.parse(params[:date]) : Date.today

      # ---- Planning du jour : tous les RDV de la date sélectionnée ----
      # includes évite les N+1 queries (on charge user et prestation d'un coup)
      @rdvs_du_jour = Booking
                        .where(date: @date)
                        .where.not(statut: 'annule')
                        .order(:heure)
                        .includes(:user, :prestation)

      # ---- RDV en attente de confirmation (toutes dates) ----
      @rdvs_en_attente = Booking
                           .where(statut: 'en_attente')
                           .where('date >= ?', Date.today)
                           .order(:date, :heure)
                           .includes(:user, :prestation)

      # ---- Statistiques globales ---- #
      # Nombre de clientes inscrites (hors admin)
      @nb_clientes = User.where(admin: false).count

      # RDV confirmés ou terminés ce mois-ci
      @nb_rdvs_mois = Booking
                        .where(statut: ['confirme', 'termine'])
                        .where(date: Date.today.beginning_of_month..Date.today.end_of_month)
                        .count

      # RDV du jour (hors annulés)
      @nb_rdvs_aujourd_hui = @rdvs_du_jour.count
    end

  end
end
