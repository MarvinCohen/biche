module Admin
  # ============================================================
  # Clientes — liste et profil complet vu par Syam
  # ============================================================
  class UsersController < BaseController

    # GET /admin/users — liste de toutes les clientes (hors admins)
    def index
      # On exclut les comptes admin (Syam elle-même)
      # Triées par ordre alphabétique du prénom
      @users = User
                 .where(admin: false)
                 .order(:last_name, :first_name)
    end

    # GET /admin/users/:id — profil complet d'une cliente
    def show
      @user = User.find(params[:id])

      # Carte fidélité
      @fidelite_card = @user.fidelite_card

      # Prochain RDV confirmé
      @prochain_rdv = @user.prochain_rdv

      # Historique complet des soins (du plus récent au plus ancien)
      @historique = @user.bookings
                         .where(statut: 'termine')
                         .order(date: :desc)
                         .includes(:prestation, :soin_historique)

      # Tous les RDV à venir
      @rdvs_futurs = @user.bookings
                          .where(statut: ['en_attente', 'confirme'])
                          .where('date >= ?', Date.today)
                          .order(:date, :heure)
                          .includes(:prestation)
    end

  end
end
