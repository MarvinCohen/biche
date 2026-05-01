class CreateGaleriePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :galerie_photos do |t|
      # Position pour trier les photos dans la galerie (ordre d'affichage)
      t.integer :position, default: 0, null: false

      # Légende principale et sous-légende affichées sur la photo
      t.string :legende,     null: false
      t.string :legende_sub

      # Catégorie pour le filtre JS : cil-a-cil, volume, rehaussement, sourcils, avant-apres
      t.string :categorie, null: false

      # Taille visuelle dans la grille masonry : tall, medium, short
      t.string :taille, default: 'medium', null: false

      t.timestamps
    end

    # Index pour trier efficacement par position
    add_index :galerie_photos, :position
    # Index pour filtrer par catégorie
    add_index :galerie_photos, :categorie
  end
end
