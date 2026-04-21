class CreateSoinHistoriques < ActiveRecord::Migration[8.1]
  def change
    create_table :soin_historiques do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :courbure
      t.string :longueur
      t.string :epaisseur
      t.string :technique
      t.text :note_syam

      t.timestamps
    end
  end
end
