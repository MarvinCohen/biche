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

  # Traite une session Checkout complétée
  # Selon le metadata présent : booking_id → réservation, order_id → carte cadeau
  def handle_checkout_completed(session)
    if session.metadata['order_id'].present?
      handle_order_completed(session)
    elsif session.metadata['booking_id'].present?
      handle_booking_completed(session)
    else
      Rails.logger.warn "Stripe: session #{session.id} sans booking_id ni order_id dans metadata"
    end
  end

  # Confirme le paiement d'une carte cadeau et envoie les emails
  def handle_order_completed(session)
    order = Order.find_by(id: session.metadata['order_id'])

    unless order
      Rails.logger.warn "Stripe: aucun order trouvé pour la session #{session.id}"
      return
    end

    # Evite de traiter deux fois si le webhook est reçu plusieurs fois
    # (orders#success peut avoir déjà mis à jour le statut)
    return unless order.statut == 'en_attente'

    # Transaction : si creer_carte_cadeau! plante, le statut 'paye' est annulé.
    # Sans ça, l'order resterait 'paye' sans carte créée, et orders#success
    # sauterait le bloc email pensant que tout est déjà fait.
    ActiveRecord::Base.transaction do
      order.update!(statut: 'paye')
      order.creer_carte_cadeau!
    end

    Rails.logger.info "Order ##{order.id} (carte cadeau) payé via Stripe"

    # Emails en dehors de la transaction — une erreur email ne doit pas
    # annuler la création de la carte en base
    OrderMailer.carte_cadeau_acheteur(order).deliver_now
    OrderMailer.carte_cadeau_destinataire(order).deliver_now
    OrderMailer.carte_cadeau_notif_syam(order).deliver_now
  end

  # Confirme le paiement d'une réservation (logique existante)
  def handle_booking_completed(session)
    booking_id = session.metadata['booking_id']
    booking    = Booking.find_by(id: booking_id)

    unless booking
      Rails.logger.warn "Stripe: aucun booking trouvé pour la session #{session.id} (booking_id: #{booking_id})"
      return
    end

    return if booking.statut == 'confirme'

    acompte = session.amount_total
    booking.update!(statut: 'confirme', acompte_cents: acompte)

    Rails.logger.info "Booking ##{booking.id} confirmé via Stripe Checkout (acompte #{acompte}cts)"

    BookingMailer.confirmation_reservation(booking).deliver_later
  end
end
