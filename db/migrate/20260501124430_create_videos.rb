class CreateVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :videos do |t|
      t.string  :titre,    null: false   # Titre affiché sous la card (ex: "Volume russe 3D")
      t.string  :url,      null: false   # Lien Instagram du reel
      t.string  :tag                     # Catégorie : extensions, rehaussement, sourcils
      t.integer :position, default: 0   # Ordre d'affichage (drag-and-drop)
      t.boolean :actif,    default: true # Masquer sans supprimer

      t.timestamps
    end

    # Index sur position pour les requêtes ORDER BY fréquentes
    add_index :videos, :position
    # Index sur actif pour filtrer les vidéos visibles
    add_index :videos, :actif
  end
end
