class CreatePrestations < ActiveRecord::Migration[8.1]
  def change
    create_table :prestations do |t|
      t.string :nom
      t.text :description
      t.integer :duree_minutes
      t.integer :prix_cents
      t.string :categorie
      t.boolean :disponible

      t.timestamps
    end
  end
end
