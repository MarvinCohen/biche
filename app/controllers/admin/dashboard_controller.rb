module Admin
  # ============================================================
  # Dashboard admin — planning du jour + statistiques globales
  # ============================================================
  class DashboardController < BaseController

    # GET /admin/agenda — vue sur 7 jours avec tous les RDV
    def agenda
      # Date de début de la semaine (aujourd'hui par défaut, ou date passée en paramètre)
      # On peut naviguer semaine par semaine avec ?date=YYYY-MM-DD
      @debut_semaine = params[:date] ? Date.parse(params[:date]) : Date.today

      # Les 7 jours à afficher (de @debut_semaine à @debut_semaine + 6 jours)
      @jours = (0..6).map { |i| @debut_semaine + i.days }

      # Tous les RDVs de la semaine (hors annulés), préchargés avec user et prestation
      @bookings_semaine = Booking
                            .where(date: @jours.first..@jours.last)
                            .where.not(statut: 'annule')
                            .order(:date, :heure)
                            .includes(:user, :prestation)

      # Grouper les bookings par date pour un accès facile dans la vue
      # { Date => [booking1, booking2, ...] }
      @bookings_par_jour = @bookings_semaine.group_by(&:date)

      # Indisponibilités qui chevauchent la semaine (couvre au moins un jour de la semaine)
      # Une indispo est pertinente si date_debut <= dernier_jour ET date_fin >= premier_jour
      indisponibilites_semaine = Indisponibilite
                                   .where('date_debut <= ? AND date_fin >= ?', @jours.last, @jours.first)
                                   .order(:date_debut, :heure_debut)

      # Grouper par jour : chaque indispo apparaît sur chaque jour qu'elle couvre
      @indisponibilites_semaine = {}
      @jours.each do |jour|
        @indisponibilites_semaine[jour] = indisponibilites_semaine.select { |i| i.couvre_le_jour?(jour) }
      end
    end

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

      # CA du jour : somme des prix des prestations confirmées ou terminées pour la date affichée
      # On fait un JOIN sur prestations pour sommer directement en base (évite le N+1)
      @ca_jour = Booking
                   .joins(:prestation)
                   .where(date: @date, statut: ['confirme', 'termine'])
                   .sum('prestations.prix_cents')

      # CA du mois : somme des prix des prestations confirmées ou terminées ce mois-ci
      @ca_mois = Booking
                   .joins(:prestation)
                   .where(
                     date: Date.today.beginning_of_month..Date.today.end_of_month,
                     statut: ['confirme', 'termine']
                   )
                   .sum('prestations.prix_cents')
    end

  end
end
