class OrderMailerPreview < ActionMailer::Preview
  # Prévisualisation de l'email reçu par le destinataire de la carte cadeau
  # Accessible sur : http://localhost:3000/rails/mailers/order_mailer/carte_cadeau_destinataire
  def carte_cadeau_destinataire
    # On utilise le dernier order payé en base pour avoir un vrai QR code
    order = Order.where(statut: 'paye').last
    OrderMailer.carte_cadeau_destinataire(order)
  end

  # Prévisualisation de l'email de confirmation envoyé à l'acheteur
  # Accessible sur : http://localhost:3000/rails/mailers/order_mailer/carte_cadeau_acheteur
  def carte_cadeau_acheteur
    order = Order.where(statut: 'paye').last
    OrderMailer.carte_cadeau_acheteur(order)
  end

  # Prévisualisation de la notification envoyée à Syam
  # Accessible sur : http://localhost:3000/rails/mailers/order_mailer/carte_cadeau_notif_syam
  def carte_cadeau_notif_syam
    order = Order.where(statut: 'paye').last
    OrderMailer.carte_cadeau_notif_syam(order)
  end
end
