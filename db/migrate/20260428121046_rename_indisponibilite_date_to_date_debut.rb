class RenameIndisponibiliteDateToDateDebut < ActiveRecord::Migration[8.1]
  def change
    # Renommer "date" en "date_debut" pour prendre en charge les plages multi-jours
    rename_column :indisponibilites, :date, :date_debut

    # Ajouter "date_fin" — si égal à date_debut, la plage ne dure qu'un jour
    add_column :indisponibilites, :date_fin, :date

    # Initialiser date_fin = date_debut pour les lignes existantes
    reversible do |dir|
      dir.up { execute "UPDATE indisponibilites SET date_fin = date_debut" }
    end

    # Rendre date_fin obligatoire maintenant qu'elle est peuplée
    change_column_null :indisponibilites, :date_fin, false

    # Ajouter l'index sur date_fin (date_debut a déjà un index — renommé automatiquement)
    add_index :indisponibilites, :date_fin
  end
end
