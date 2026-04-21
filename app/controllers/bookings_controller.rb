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

  # POST /bookings — crée la réservation et redirige vers le paiement
  def create
    @booking = Booking.new(booking_params)
    @booking.user   = current_user   # On associe la cliente connectée
    @booking.statut = 'en_attente'   # Statut initial avant paiement

    if @booking.save
      # Succès : on affiche la page de confirmation
      redirect_to @booking, notice: "Réservation enregistrée ! Confirmez avec le paiement."
    else
      # Échec : on réaffiche le formulaire avec les erreurs
      @prestations = Prestation.disponibles.par_nom
      render :new, status: :unprocessable_entity
    end
  end

  # GET /bookings/:id — confirmation de réservation
  def show
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

    # Créneaux déjà réservés ce jour-là
    bookings_du_jour = Booking.where(date: date).where.not(statut: 'annule').pluck(:heure)

    # Créneaux de travail : 9h → 18h par tranches de 90 minutes
    tous_les_creneaux = (9..17).step(1.5).map { |h| Time.parse("#{h.to_i}:#{(h % 1 * 60).to_i.to_s.rjust(2,'0')}") }

    # On filtre les créneaux déjà pris
    @creneaux_disponibles = tous_les_creneaux.reject { |c| bookings_du_jour.include?(c.strftime('%H:%M:00')) }

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
