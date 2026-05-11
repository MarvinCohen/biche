class AddIndexesToBookings < ActiveRecord::Migration[8.1]
  def change
    # Index sur date — utilisée dans presque toutes les requêtes critiques
    # (planning du jour, créneaux disponibles, agenda semaine)
    add_index :bookings, :date

    # Index composite date + statut — utilisé pour filtrer les RDVs actifs d'un jour donné
    # Ex : WHERE date = ? AND statut != 'annule'
    add_index :bookings, [:date, :statut]

    # Index sur statut seul — utilisé pour les stats et les listes par statut
    add_index :bookings, :statut

    # Index sur orders.statut — filtré fréquemment pour les cartes actives/épuisées
    add_index :orders, :statut
  end
end
