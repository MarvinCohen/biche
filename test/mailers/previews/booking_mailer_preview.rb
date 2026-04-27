# ============================================================
# Preview des emails BookingMailer
# Accessible sur : http://localhost:3000/rails/mailers/booking_mailer
#
# Utilise le premier booking en base pour afficher un rendu réel.
# Si la base est vide, les previews renverront une erreur — lancer
# `rails db:seed` pour peupler des données de test.
# ============================================================
class BookingMailerPreview < ActionMailer::Preview

  # Preview : email de confirmation après réservation
  # URL : /rails/mailers/booking_mailer/confirmation_reservation
  def confirmation_reservation
    booking = Booking.includes(:user, :prestation).first
    BookingMailer.confirmation_reservation(booking)
  end

  # Preview : email de confirmation par Syam
  # URL : /rails/mailers/booking_mailer/rdv_confirme
  def rdv_confirme
    booking = Booking.includes(:user, :prestation).first
    BookingMailer.rdv_confirme(booking)
  end

  # Preview : email de rappel 24h avant
  # URL : /rails/mailers/booking_mailer/rappel_rdv
  def rappel_rdv
    booking = Booking.includes(:user, :prestation).first
    BookingMailer.rappel_rdv(booking)
  end

end
