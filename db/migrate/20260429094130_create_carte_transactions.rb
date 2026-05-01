class CreateCarteTransactions < ActiveRecord::Migration[8.1]
  def change
    # Historique de chaque utilisation d'une carte cadeau
    create_table :carte_transactions do |t|
      # Carte cadeau concernée — foreign_key pointe vers la vraie table cartes_cadeaux
      t.references :carte_cadeau, null: false, foreign_key: { to_table: :cartes_cadeaux }

      # Montant déduit en centimes (toujours positif, la déduction est gérée dans le modèle)
      t.integer :montant_cents, null: false

      # Description de l'utilisation (ex: "Pose cil à cil", "Retouche volume")
      t.string :description

      # Lien optionnel avec un booking si la carte est utilisée pour un RDV
      t.integer :booking_id

      t.timestamps
    end
  end
end
