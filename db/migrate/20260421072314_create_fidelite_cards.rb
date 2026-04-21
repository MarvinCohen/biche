class CreateFideliteCards < ActiveRecord::Migration[8.1]
  def change
    create_table :fidelite_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :points
      t.integer :visites
      t.integer :recompenses_utilisees

      t.timestamps
    end
  end
end
