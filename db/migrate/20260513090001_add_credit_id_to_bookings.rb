# ============================================================
# Migration — Ajout de credit_id sur bookings
#
# Permet à un Booking d'être lié au crédit utilisé pour le payer.
# - credit_id nullable : la majorité des bookings sont payés normalement (Stripe),
#   `credit_id` n'est rempli que si la cliente utilise un de ses crédits de pack.
# - Quand un booking est marqué "terminé" et qu'il a un `credit_id`, on décrémente
#   `credit.nb_restant` (logique dans Admin::BookingsController#terminer).
# ============================================================
class AddCreditIdToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :credit, null: true, foreign_key: true
  end
end
