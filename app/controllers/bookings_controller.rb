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
    date       = Date.parse(params[:date])
    prestation = Prestation.find(params[:prestation_id])
    duree      = prestation.duree_minutes.minutes

    # Créneaux de travail : 9h → 16h30 par tranches de 1h30
    tous_les_creneaux = (9..17).step(1.5).map do |h|
      Time.parse("#{h.to_i}:#{(h % 1 * 60).to_i.to_s.rjust(2, '0')}")
    end

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
  def booking_params
    params.require(:booking).permit(:prestation_id, :date, :heure, :mode_paiement, :notes_cliente)
  end
end
