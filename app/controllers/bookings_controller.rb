class BookingsController < ApplicationController
  # ============================================================
  # Réservations — requiert d'être connectée
  # ============================================================
  before_action :authenticate_user!  # Devise : redirige vers login si non connectée
  before_action :set_booking, only: [:show, :destroy]

  # GET /bookings/new — formulaire de réservation (4 étapes)
  def new
    @booking     = Booking.new
    # On charge toutes les prestations dispo pour l'étape 1 (choix du soin)
    # On exclut les prestations "sourcils" : Syam ne propose pas (encore)
    # cette catégorie de soin. Pour la réactiver plus tard, supprimer le
    # `.where.not(...)` et remettre la pill "Sourcils" dans la vue.
    @prestations = Prestation.disponibles.par_nom.where.not(categorie: 'sourcils')
    # Jours de la semaine fermés (0=dimanche … 6=samedi) — passé au JS Stimulus
    # pour griser les jours fermés dans le calendrier de réservation.
    @jours_fermes = BusinessHour.where(ouvert: false).pluck(:day_of_week)

    # Dates couvertes par des indispos « jour entier » sur les 3 prochains mois
    # (limite raisonnable du payload — la cliente ne réserve pas plus loin en pratique).
    # Format : tableau de strings "YYYY-MM-DD" attendu par le JS du calendrier.
    @jours_bloques = Indisponibilite.dates_jour_entier_entre(Date.today, Date.today + 3.months)

    # Crédits de remplissage encore utilisables par la cliente.
    # On les passe au JS via data-attributes pour afficher dynamiquement le banner
    # "Utiliser un crédit" si la prestation choisie est applicable à un de ses crédits.
    # `includes(:prestation)` évite N+1 (on affiche le nom de la pose dans le banner).
    @credits_actifs = current_user.credits_actifs.includes(:prestation)
  end

  # POST /bookings — crée la réservation et redirige vers Stripe Checkout
  # OU saute Stripe si la cliente utilise un crédit de pack.
  def create
    @booking = Booking.new(booking_params)
    @booking.user   = current_user

    # ----- CAS CRÉDIT : la cliente utilise un crédit de pack -----
    # On vérifie côté serveur (jamais confiance au form) :
    #  1. le crédit existe ET appartient bien à la cliente connectée
    #  2. il est encore actif (non épuisé, non expiré)
    #  3. il est applicable à la prestation choisie (matching nom)
    # Si tout est OK : pas de Stripe, statut direct `confirme`, mode `credit`.
    credit = nil
    if params[:booking][:credit_id].present?
      # `current_user.credits` borne automatiquement à la cliente connectée
      # → impossible d'utiliser un crédit d'une autre user (paramètre forgé).
      credit = current_user.credits.actifs.find_by(id: params[:booking][:credit_id])

      if credit && credit.applicable_a?(@booking.prestation)
        # Pré-configure le booking : on saute le flux Stripe
        @booking.statut         = 'confirme'
        @booking.mode_paiement  = 'credit'
        @booking.credit         = credit
      else
        # Crédit invalide / expiré / non applicable → on tombe en erreur explicite
        # plutôt que de payer en Stripe (ce serait surprenant pour la cliente).
        # Sourcils exclus (cf. action new) — Syam ne propose pas cette catégorie
        @prestations    = Prestation.disponibles.par_nom.where.not(categorie: 'sourcils')
        @jours_fermes   = BusinessHour.where(ouvert: false).pluck(:day_of_week)
        @jours_bloques  = Indisponibilite.dates_jour_entier_entre(Date.today, Date.today + 3.months)
        @credits_actifs = current_user.credits_actifs.includes(:prestation)
        flash.now[:alert] = "Ce crédit n'est plus utilisable ou ne s'applique pas à cette prestation."
        render :new, status: :unprocessable_entity
        return
      end
    else
      # Flux normal : statut initial → passe à `confirme` après paiement Stripe
      @booking.statut = 'en_attente'
    end

    if @booking.save
      # ----- BRANCHE CRÉDIT : pas de Stripe, on redirige direct -----
      if credit
        # On ne décrémente PAS le crédit ici — c'est fait au moment où Syam
        # marque le RDV "terminé" (cf. Admin::BookingsController#terminer).
        # Logique : tant que le RDV n'a pas eu lieu, le crédit n'est pas consommé
        # → ainsi une annulation suffit à le restituer (pas de logique complexe).
        redirect_to @booking,
                    notice: "Rendez-vous confirmé avec votre crédit. À très vite chez Biche."
        return
      end

      if @booking.mode_paiement == 'acompte'
        # Acompte calculé par le modèle (30% du prix) — évite la duplication de logique métier
        acompte_cents = @booking.acompte_calcule_cents

        # Création de la session Stripe Checkout — Stripe héberge la page de paiement
        session = Stripe::Checkout::Session.create(
          mode:          'payment',
          payment_method_types: ['card'],
          line_items: [{
            price_data: {
              currency:     'eur',
              unit_amount:  acompte_cents,
              product_data: {
                name:        "Acompte — #{@booking.prestation.nom}",
                description: "30% du prix total (#{@booking.prestation.prix_euros}€). Solde réglé sur place."
              }
            },
            quantity: 1
          }],
          # L'ID du booking est passé en metadata pour le retrouver dans le webhook
          metadata: { booking_id: @booking.id },
          # URL de retour après paiement réussi
          success_url: success_bookings_url(booking_id: @booking.id, session_id: '{CHECKOUT_SESSION_ID}'),
          # URL de retour en cas d'annulation (retour au formulaire)
          cancel_url:  new_booking_url
        )

        # On stocke l'ID de session Stripe sur le booking pour le retrouver dans le webhook
        @booking.update!(stripe_payment_intent_id: session.id)

        # Redirection vers la page de paiement Stripe
        redirect_to session.url, allow_other_host: true

      else
        # Mode empreinte : pas de paiement immédiat — à implémenter avec Stripe SetupIntent
        redirect_to @booking, notice: "Réservation enregistrée. Syam vous confirmera le créneau."
      end

    else
      # Échec de validation : on réaffiche le formulaire avec les erreurs.
      # On recharge TOUTES les données nécessaires au render (sinon vues plantent).
      # Sourcils exclus (cf. action new) — Syam ne propose pas cette catégorie
      @prestations    = Prestation.disponibles.par_nom.where.not(categorie: 'sourcils')
      @jours_fermes   = BusinessHour.where(ouvert: false).pluck(:day_of_week)
      @jours_bloques  = Indisponibilite.dates_jour_entier_entre(Date.today, Date.today + 3.months)
      @credits_actifs = current_user.credits_actifs.includes(:prestation)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /bookings/:id — confirmation de réservation
  def show
  end

  # GET /bookings/success — page de retour après paiement Stripe réussi
  # Stripe redirige ici avec ?booking_id=X&session_id=cs_...
  def success
    @booking = current_user.bookings.find(params[:booking_id])
  end

  # DELETE /bookings/:id — annulation d'un rendez-vous
  def destroy
    # On annule plutôt qu'on supprime pour garder l'historique
    @booking.update!(statut: 'annule')
    redirect_to espace_cliente_root_path, notice: "Rendez-vous annulé."
  end

  # GET /bookings/creneaux — retourne les créneaux disponibles pour une date (AJAX)
  def creneaux
    # Date.parse lève ArgumentError si le paramètre est absent ou malformé → on retourne []
    date = Date.parse(params[:date].to_s) rescue nil
    # find_by retourne nil au lieu de lever RecordNotFound si l'id est invalide
    prestation = Prestation.find_by(id: params[:prestation_id])

    # Paramètres invalides → réponse vide (évite une erreur 500)
    return render json: [] unless date && prestation

    # Créneaux de travail générés à partir de la semaine type configurée par Syam
    # (table `business_hours`, éditable depuis l'admin).
    # La méthode renvoie [] si le jour est fermé OU si aucun horaire n'est configuré
    # → dans ce cas on court-circuite le calcul de conflits inutile.
    tous_les_creneaux = BusinessHour.creneaux_pour(date, prestation.duree_minutes)
    return render json: [] if tous_les_creneaux.empty?

    # Charger les RDVs existants du jour avec leur prestation (pour connaître la durée)
    rdvs_existants = Booking
                       .where(date: date)
                       .where.not(statut: 'annule')
                       .includes(:prestation)

    # Indisponibilités couvrant ce jour (date_debut <= date <= date_fin)
    indisponibilites = Indisponibilite.where('date_debut <= ? AND date_fin >= ?', date, date)

    # Convertir en secondes depuis minuit pour comparer les heures sans ambiguïté de date
    # (Rails stocke :time avec la date 2000-01-01, Time.parse prend la date courante)
    to_s = ->(t) { t.hour * 3600 + t.min * 60 }
    duree_s = prestation.duree_minutes * 60

    # Rejeter les créneaux qui créeraient un chevauchement avec un RDV existant
    # OU qui tombent dans une indisponibilité bloquée par Syam
    @creneaux_disponibles = tous_les_creneaux.reject do |c|
      nouveau_debut_s = to_s.call(c)
      nouveau_fin_s   = nouveau_debut_s + duree_s

      # Conflit avec un RDV existant
      conflit_rdv = rdvs_existants.any? do |rdv|
        existant_debut_s = to_s.call(rdv.heure)
        existant_fin_s   = existant_debut_s + rdv.prestation.duree_minutes * 60
        nouveau_debut_s < existant_fin_s && nouveau_fin_s > existant_debut_s
      end

      # Conflit avec une indisponibilité (pause déjeuner, congé, etc.)
      conflit_indispo = indisponibilites.any? do |indispo|
        indispo_debut_s = to_s.call(indispo.heure_debut)
        indispo_fin_s   = to_s.call(indispo.heure_fin)
        nouveau_debut_s < indispo_fin_s && nouveau_fin_s > indispo_debut_s
      end

      conflit_rdv || conflit_indispo
    end

    render json: @creneaux_disponibles.map { |c| c.strftime('%Hh%M') }
  end

  private

  # Cherche la réservation en cours et vérifie qu'elle appartient bien à la cliente connectée
  def set_booking
    @booking = current_user.bookings.find(params[:id])
  end

  # Paramètres autorisés pour créer une réservation (protection contre la manipulation)
  # `:credit_id` est permis mais re-vérifié côté serveur dans `create` (sécurité :
  # une cliente ne peut pas utiliser un crédit qui ne lui appartient pas).
  def booking_params
    params.require(:booking).permit(:prestation_id, :date, :heure, :mode_paiement, :notes_cliente, :credit_id)
  end
end
