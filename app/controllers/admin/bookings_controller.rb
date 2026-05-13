module Admin
  # ============================================================
  # Réservations — liste et gestion des statuts
  # ============================================================
  class BookingsController < BaseController
    before_action :set_booking, only: [:show, :confirmer, :terminer, :annuler]

    # GET /admin/bookings/creneaux — créneaux disponibles toutes les 15 min (AJAX admin)
    # Même logique anti-chevauchement que le controller client, mais toutes les 15 min
    def creneaux
      # Date.parse lève ArgumentError si le paramètre est absent ou malformé → on retourne []
      date = Date.parse(params[:date].to_s) rescue nil
      # find_by retourne nil au lieu de lever RecordNotFound si l'id est invalide
      prestation = Prestation.find_by(id: params[:prestation_id])

      # Paramètres invalides → réponse vide (évite une erreur 500)
      return render json: [] unless date && prestation

      duree = prestation.duree_minutes.minutes

      # Créneaux de 8h00 à 19h45 toutes les 15 minutes
      tous_les_creneaux = (8..19).flat_map do |h|
        [0, 15, 30, 45].map do |m|
          Time.parse("#{h.to_s.rjust(2, '0')}:#{m.to_s.rjust(2, '0')}")
        end
      end

      # RDVs existants du jour (hors annulés) avec leur prestation pour calculer la durée
      rdvs_existants = Booking
                         .where(date: date)
                         .where.not(statut: 'annule')
                         .includes(:prestation)

      # Indisponibilités couvrant ce jour (date_debut <= date <= date_fin)
      indisponibilites = Indisponibilite.where('date_debut <= ? AND date_fin >= ?', date, date)

      # Convertir un objet Time en secondes depuis minuit (heure + minutes uniquement)
      # Nécessaire car Rails stocke les colonnes :time avec la date 2000-01-01,
      # tandis que Time.parse("10:00") utilise la date d'aujourd'hui.
      # Comparer les objets Time directement donnerait des résultats faux.
      to_s = ->(t) { t.hour * 3600 + t.min * 60 }

      duree_s = prestation.duree_minutes * 60

      # Rejeter les créneaux qui créeraient un chevauchement avec un RDV existant
      # OU qui tombent dans une indisponibilité
      disponibles = tous_les_creneaux.reject do |c|
        nouveau_debut_s = to_s.call(c)
        nouveau_fin_s   = nouveau_debut_s + duree_s

        # Vérifier le chevauchement avec un RDV existant
        conflit_rdv = rdvs_existants.any? do |rdv|
          existant_debut_s = to_s.call(rdv.heure)
          existant_fin_s   = existant_debut_s + rdv.prestation.duree_minutes * 60
          nouveau_debut_s < existant_fin_s && nouveau_fin_s > existant_debut_s
        end

        # Vérifier le chevauchement avec une indisponibilité bloquée
        conflit_indispo = indisponibilites.any? do |indispo|
          indispo_debut_s = to_s.call(indispo.heure_debut)
          indispo_fin_s   = to_s.call(indispo.heure_fin)
          nouveau_debut_s < indispo_fin_s && nouveau_fin_s > indispo_debut_s
        end

        conflit_rdv || conflit_indispo
      end

      # Retourner label + value pour peupler le select côté JS
      render json: disponibles.map { |c| { label: c.strftime('%Hh%M'), value: c.strftime('%H:%M') } }
    end

    # GET /admin/bookings/new — formulaire de création manuelle d'un RDV
    def new
      @booking = Booking.new
      # Pré-remplir la date si passée en paramètre (depuis le planning) — rescue si malformée
      @booking.date = params[:date] ? (Date.parse(params[:date]) rescue Date.today) : Date.today

      # Listes pour les selects du formulaire
      @clientes    = User.where(admin: false).order(:last_name, :first_name)
      @prestations = Prestation.disponibles.order(:categorie, :nom)
    end

    # POST /admin/bookings — création manuelle d'un RDV par Syam
    def create
      # Si Syam crée une nouvelle cliente à la volée (pas dans la base)
      if params[:nouvelle_cliente] == '1'
        user = creer_nouvelle_cliente
        # En cas d'erreur de création de la cliente, on reaffiche le formulaire
        unless user
          @clientes    = User.where(admin: false).order(:last_name, :first_name)
          @prestations = Prestation.disponibles.order(:categorie, :nom)
          flash.now[:alert] = "Impossible de créer la cliente. Vérifiez le prénom et le nom."
          return render :new, status: :unprocessable_entity
        end
        # Injecter l'id de la nouvelle cliente dans les params du booking
        params[:booking][:user_id] = user.id
      end

      @booking = Booking.new(booking_admin_params)
      # Un RDV créé manuellement est directement confirmé
      @booking.statut        = 'confirme'
      # Pas de paiement en ligne pour les RDV manuels — acompte par défaut
      @booking.mode_paiement = 'acompte'
      # Bypass de la validation horaires d'ouverture : Syam peut forcer
      # un créneau hors horaires (ex : amie qui passe en dehors des heures normales)
      @booking.skip_business_hours_validation = true

      if @booking.save
        # Envoyer l'email de confirmation uniquement si la cliente a un vrai email
        BookingMailer.confirmation_reservation(@booking).deliver_later unless @booking.user.email.include?('@client.biche')

        redirect_to admin_booking_path(@booking),
                    notice: "RDV créé pour #{@booking.user.full_name}."
      else
        @clientes    = User.where(admin: false).order(:last_name, :first_name)
        @prestations = Prestation.disponibles.order(:categorie, :nom)
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/bookings/:id — détail complet d'un RDV
    def show
      # @booking est chargé par set_booking
      # On charge aussi la fiche soin si elle existe
      @soin_historique = @booking.soin_historique
    end

    # PATCH /admin/bookings/:id/confirmer — passe le statut à "confirme"
    def confirmer
      # On ne confirme que si le RDV est en attente
      if @booking.statut == 'en_attente'
        @booking.update!(statut: 'confirme')

        # Prévenir la cliente par email que son RDV est confirmé
        BookingMailer.rdv_confirme(@booking).deliver_later

        redirect_to admin_booking_path(@booking), notice: "Réservation confirmée. Email envoyé à la cliente."
      else
        redirect_to admin_booking_path(@booking), alert: "Ce RDV ne peut pas être confirmé."
      end
    end

    # PATCH /admin/bookings/:id/terminer — marque le soin comme terminé
    def terminer
      # On ne termine que si le RDV est confirmé
      if @booking.statut == 'confirme'
        @booking.update!(statut: 'termine')

        # Créditer un point fidélité à la cliente (Fat Model : logique dans FideliteCard)
        fidelite = @booking.user.fidelite_card
        fidelite.ajouter_visite! if fidelite

        # Si le RDV était payé avec un crédit de pack → décrémenter `nb_restant`.
        # On le fait ici (et pas à la création du booking) pour 2 raisons :
        # 1. Tant que le soin n'a pas eu lieu, le crédit n'est pas vraiment "consommé"
        #    → une annulation suffit à le restituer sans logique supplémentaire.
        # 2. Le terminer-marquage par Syam est l'évènement métier qui actualise tout
        #    (fidélité, statut, et donc le crédit aussi — cohérent).
        # `utiliser!` lève si le crédit est épuisé/expiré (cas anormal ici, déjà vérifié
        # à la création du booking) — on log l'erreur et continue.
        if @booking.credit
          begin
            @booking.credit.utiliser!
          rescue => e
            Rails.logger.error "terminer — erreur décrémentation crédit ##{@booking.credit_id} : #{e.message}"
          end
        end

        # Message adapté selon que le RDV a consommé un crédit ou non
        message = "Soin marqué comme terminé. 1 point fidélité crédité."
        message += " 1 remplissage consommé sur le crédit." if @booking.credit
        redirect_to admin_booking_path(@booking), notice: message
      else
        redirect_to admin_booking_path(@booking), alert: "Ce RDV ne peut pas être marqué comme terminé."
      end
    end

    # PATCH /admin/bookings/:id/annuler — annule la réservation et prévient la cliente
    def annuler
      # On peut annuler n'importe quel RDV non déjà annulé
      unless @booking.statut == 'annule'
        @booking.update!(statut: 'annule')

        # Prévenir la cliente par email (sauf si elle n'a pas de vrai email — placeholder @client.biche)
        unless @booking.user.email.include?('@client.biche')
          BookingMailer.rdv_annule(@booking).deliver_later
        end

        # Le planning du jour est désormais sur le dashboard (admin_root_path)
        redirect_to admin_root_path(date: @booking.date), notice: "Réservation annulée. Email envoyé à la cliente."
      else
        redirect_to admin_booking_path(@booking), alert: "Ce RDV est déjà annulé."
      end
    end

    private

    # Charge la réservation — pas de restriction user ici (admin voit tout)
    def set_booking
      @booking = Booking.find(params[:id])
    end

    # Champs autorisés pour la création manuelle par Syam
    # statut et mode_paiement sont exclus — forcés dans l'action create
    def booking_admin_params
      params.require(:booking).permit(:user_id, :prestation_id, :date, :heure, :notes_cliente)
    end

    # Crée une nouvelle cliente à la volée depuis les champs du formulaire
    # Génère un email placeholder et un mot de passe aléatoire (la cliente ne se connecte pas)
    def creer_nouvelle_cliente
      prenom = params[:nouvelle_first_name].to_s.strip
      nom    = params[:nouvelle_last_name].to_s.strip
      phone  = params[:nouvelle_phone].to_s.strip
      return nil if prenom.blank? || nom.blank?

      # Email unique généré automatiquement — la cliente ne s'en sert pas
      email_placeholder = "#{prenom.downcase.gsub(/\s/, '-')}.#{nom.downcase.gsub(/\s/, '-')}.#{Time.now.to_i}@client.biche"

      User.create(
        first_name: prenom,
        last_name:  nom,
        phone:      phone.presence,
        email:      email_placeholder,
        password:   SecureRandom.hex(12)  # Mot de passe aléatoire — jamais utilisé
      )
    end
  end
end
