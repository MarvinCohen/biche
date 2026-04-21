class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :statut
      t.string :stripe_payment_intent_id
      t.integer :montant_cents
      t.string :destinataire_email
      t.string :destinataire_nom

      t.timestamps
    end
  end
end
