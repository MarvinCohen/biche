class OrderMailer < ApplicationMailer
  # ============================================================
  # Emails liés aux commandes boutique (cartes cadeaux, packs)
  # ============================================================

  # Email 1 — Confirmation à l'acheteur après commande d'une carte cadeau
  # Déclenché par : OrdersController#create
  def carte_cadeau_acheteur(order)
    @order  = order
    @user   = order.user   # La cliente qui offre la carte
    @montant = order.montant_cents / 100

    mail(
      to:      @user.email,
      subject: "Votre carte cadeau Biche. est enregistrée ✨"
    )
  end

  # Email 2 — Carte cadeau envoyée directement au destinataire avec le code + QR code
  # Déclenché par : OrdersController#success (après paiement Stripe confirmé)
  def carte_cadeau_destinataire(order)
    @order    = order
    @acheteur = order.user
    @montant  = order.montant_cents / 100
    # Récupérer la carte créée après paiement pour avoir son code unique
    @carte    = order.cartes_cadeaux.last

    mail(
      to:      @order.destinataire_email,
      subject: "#{@acheteur.first_name} vous offre une carte cadeau Biche. 🎁"
    )
  end

  # Email 3 — Notification à Syam (pour info, pas d'action requise)
  # Déclenché par : OrdersController#create
  def carte_cadeau_notif_syam(order)
    @order    = order
    @acheteur = order.user
    @montant  = order.montant_cents / 100

    mail(
      to:      "syam@biche-bordeaux.fr",
      subject: "Nouvelle carte cadeau — #{@montant}€ · Biche."
    )
  end
end
