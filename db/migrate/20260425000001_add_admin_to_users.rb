class AddAdminToUsers < ActiveRecord::Migration[8.1]
  def change
    # Ajoute un flag booléen "admin" sur les utilisateurs
    # Par défaut false : toutes les clientes existantes restent des clientes normales
    # Seule Syam aura admin: true (à faire manuellement en console Rails)
    add_column :users, :admin, :boolean, default: false, null: false

    # Index pour accélérer les requêtes "WHERE admin = true" (chercher Syam)
    add_index :users, :admin
  end
end
