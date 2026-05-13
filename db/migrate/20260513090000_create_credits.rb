# ============================================================
# Migration — Création de la table credits
#
# Un credit = un droit à une retouche de remplissage, attribué à une cliente
# après l'achat d'un pack (Product type='pack').
#
# Cycle de vie :
# - Création quand la cliente achète un pack (1 Credit par Order de pack,
#   `nb_total` = `nb_remplissages` du pack acheté).
# - Décrémenté quand un RDV de retouche utilisant ce credit est marqué
#   "terminé" par Syam (nb_restant -= 1).
# - Expire à `date_expiration` (calculée = aujourd'hui + nb_remplissages mois).
# ============================================================
class CreateCredits < ActiveRecord::Migration[8.1]
  def change
    create_table :credits do |t|
      # Cliente propriétaire du crédit
      t.references :user, null: false, foreign_key: true

      # Order à l'origine de l'attribution (pour traçabilité + affichage historique).
      # On ne `dependent: destroy` pas : si on supprime un Order, on garde le Credit
      # pour ne pas faire disparaître silencieusement les droits de la cliente.
      t.references :order, null: false, foreign_key: true

      # Prestation de pose (catégorie 'extensions') à laquelle ce crédit est rattaché.
      # Ex : crédit "Volume léger" → utilisable sur les retouches Volume léger.
      t.references :prestation, null: false, foreign_key: true

      # Nombre de remplissages au total (3, 6 ou 9 — copié du pack à l'achat).
      # On stocke ce nombre figé pour conserver l'historique même si Syam
      # modifie ensuite le pack en admin.
      t.integer :nb_total, null: false

      # Nombre de remplissages restants. Démarre à `nb_total` et est
      # décrémenté à chaque RDV terminé.
      t.integer :nb_restant, null: false

      # Date d'expiration du crédit (au-delà, il devient inutilisable).
      # Calculée à la création : Date.today + nb_remplissages.months.
      t.date :date_expiration, null: false

      t.timestamps
    end

    # Index utile pour le scope `actifs` (nb_restant > 0 AND date_expiration >= today)
    # — souvent appelé dans la vue espace cliente + sur le formulaire de booking.
    add_index :credits, [:user_id, :date_expiration]
  end
end
