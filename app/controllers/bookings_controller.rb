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
    @prestations = Prestation.disponibles.par_nom
  end

  # POST /bookings — crée la réservation et redirige vers Stripe Checkout
  def create
    @booking = Booking.new(booking_params)
    @booking.user   = current_user
    @booking.statut = 'en_attente'  # Statut initial — passe à 'confirme' après paiement Stripe

    if @booking.save
      if @booking.mode_paiement == 'acompte'
        # Calcul de l'acompte : 30% du prix de la prestation, en centimes
        acompte_cents = (@booking.prestation.prix_cents * 0.30).ceil

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
      # Échec de validation : on réaffiche le formulaire avec les erreurs
      @prestations = Prestation.disponibles.par_nom
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
    # La date est passée en paramètre GET depuis le calendrier JS
    date         = Date.parse(params[:date])
    prestation   = Prestation.find(params[:prestation_id])

    # Créneaux de travail : 9h → 16h30 par tranches de 1h30
    # (9..17).step(1.5) génère : 9.0, 10.5, 12.0, 13.5, 15.0, 16.5
    tous_les_creneaux = (9..17).step(1.5).map do |h|
      Time.parse("#{h.to_i}:#{(h % 1 * 60).to_i.to_s.rjust(2, '0')}")
    end

    # Heures déjà réservées ce jour-là, converties en "HH:MM" pour comparer
    # Pluck retourne des objets Time en Rails — on normalise en string pour la comparaison
    prises = Booking
               .where(date: date)
               .where.not(statut: 'annule')
               .pluck(:heure)
               .map { |h| h.strftime('%H:%M') }

    # On retire les créneaux déjà pris (comparaison string → string, pas Time → string)
    @creneaux_disponibles = tous_les_creneaux.reject do |c|
      prises.include?(c.strftime('%H:%M'))
    end

    render json: @creneaux_disponibles.map { |c| c.strftime('%Hh%M') }
  end

  private

  # Cherche la réservation en cours et vérifie qu'elle appartient bien à la cliente connectée
  def set_booking
    @booking = current_user.bookings.find(params[:id])
  end

  # Paramètres autorisés pour créer une réservation (protection contre la manipulation)
  def booking_params
    params.require(:booking).permit(:prestation_id, :date, :heure, :mode_paiement, :notes_cliente)
  end
end
