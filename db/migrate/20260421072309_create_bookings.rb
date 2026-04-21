class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prestation, null: false, foreign_key: true
      t.date :date
      t.time :heure
      t.string :statut
      t.string :mode_paiement
      t.string :stripe_payment_intent_id
      t.integer :acompte_cents
      t.text :notes_cliente

      t.timestamps
    end
  end
end
