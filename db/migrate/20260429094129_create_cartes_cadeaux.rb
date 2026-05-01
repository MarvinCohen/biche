class CreateCartesCadeaux < ActiveRecord::Migration[8.1]
  def change
    # Table des cartes cadeaux émises après paiement Stripe confirmé
    create_table :cartes_cadeaux do |t|
      # Lien avec la commande qui a généré cette carte
      t.references :order,   null: false, foreign_key: true

      # Code unique affiché sur la carte et dans le QR code (ex: BICHE-A7X2-9K4M)
      t.string  :code,                   null: false

      # Montant d'origine (en centimes) — ne change jamais
      t.integer :montant_initial_cents,  null: false

      # Solde restant (en centimes) — décrémenté à chaque utilisation
      t.integer :solde_cents,            null: false

      # Active = false quand solde = 0 ou carte annulée
      t.boolean :active, default: true,  null: false

      t.timestamps
    end

    # Index unique sur le code pour retrouver une carte rapidement
    add_index :cartes_cadeaux, :code,   unique: true
    # Index pour retrouver la carte d'une commande
    add_index :cartes_cadeaux, :active
  end
end
