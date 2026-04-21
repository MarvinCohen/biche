class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :user, null: false, foreign_key: true
      t.string :titre
      t.text :contenu
      t.string :type_message
      t.boolean :lu

      t.timestamps
    end
  end
end
