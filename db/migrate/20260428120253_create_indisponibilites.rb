class CreateIndisponibilites < ActiveRecord::Migration[8.1]
  def change
    create_table :indisponibilites do |t|
      t.date   :date,        null: false
      t.time   :heure_debut, null: false
      t.time   :heure_fin,   null: false
      t.string :raison  # Ex: "Pause déjeuner", "Congé", etc. — optionnel

      t.timestamps
    end

    # Index sur la date pour accélérer les requêtes lors du calcul des créneaux
    add_index :indisponibilites, :date
  end
end
