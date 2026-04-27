class StripeController < ApplicationController
  # ============================================================
  # Webhook Stripe — reçoit les événements de paiement
  # Route : POST /stripe/webhook
  # ============================================================

  # Stripe envoie des requêtes POST sans cookie de session
  # → on désactive la protection CSRF pour cette route uniquement
  skip_before_action :verify_authenticity_token

  def webhook
    payload    = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']

    # Vérification de la signature Stripe pour s'assurer que la requête est légitime
    event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)

    # Traitement selon le type d'événement reçu
    case event['type']
    when 'checkout.session.completed'
      # La session Checkout est terminée et le paiement confirmé
      handle_checkout_completed(event['data']['object'])
    when 'checkout.session.expired'
      # La cliente n'a pas payé dans le délai — on peut notifier ou annuler
      Rails.logger.warn "Stripe: session expirée #{event['data']['object']['id']}"
    end

    # Stripe attend un 200 pour confirmer la réception de l'événement
    render json: { received: true }, status: :ok

  rescue Stripe::SignatureVerificationError => e
    # Signature invalide = requête non authentifiée (attaque potentielle)
    Rails.logger.error "Stripe webhook signature invalide : #{e.message}"
    render json: { error: 'Invalid signature' }, status: :bad_request

  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe webhook erreur : #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  # Traite une session Checkout complétée : confirme le booking
  def handle_checkout_completed(session)
    # L'ID du booking est stocké dans les metadata de la session Stripe
    # session est un objet Stripe Ruby → on utilise la notation point, pas dig
    booking_id = session.metadata['booking_id']
    booking    = Booking.find_by(id: booking_id)

    unless booking
      Rails.logger.warn "Stripe: aucun booking trouvé pour la session #{session.id} (booking_id: #{booking_id})"
      return
    end

    # Evite de confirmer deux fois si le webhook est reçu plusieurs fois
    return if booking.statut == 'confirme'

    # Montant reçu par Stripe (en centimes)
    acompte = session.amount_total

    booking.update!(
      statut:        'confirme',
      acompte_cents: acompte
    )

    Rails.logger.info "Booking ##{booking.id} confirmé via Stripe Checkout (acompte #{acompte}cts)"

    # Email de confirmation envoyé à la cliente après paiement
    BookingMailer.confirmation_reservation(booking).deliver_later
  end
end
