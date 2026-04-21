class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :nom
      t.text :description
      t.integer :prix_cents
      t.string :type_produit
      t.boolean :actif

      t.timestamps
    end
  end
end
