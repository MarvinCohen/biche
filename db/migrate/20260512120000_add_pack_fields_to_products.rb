# ============================================================
# Migration — Ajout des champs spécifiques aux packs de remplissage
#
# Pourquoi :
# Les "packs" sont désormais déclinés par type de pose (Cil à cil,
# Volume léger, etc.) et par nombre de remplissages (3, 6 ou 9).
# Auparavant ils étaient génériques — désormais on doit lier chaque
# pack à la prestation de pose qu'il concerne, et stocker le nombre
# de remplissages inclus.
#
# Les deux colonnes sont **nullables** car les autres types de produits
# (cartes cadeaux, routine) n'utilisent pas ces champs.
# Les validations conditionnelles côté modèle imposent leur présence
# uniquement quand type_produit = 'pack'.
# ============================================================
class AddPackFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    # Référence vers la prestation de pose complète (catégorie 'extensions').
    # On utilise `foreign_key: true` pour garantir l'intégrité référentielle
    # côté PostgreSQL (impossible d'avoir un prestation_id qui ne correspond
    # à aucune ligne dans `prestations`).
    add_reference :products, :prestation, null: true, foreign_key: true

    # Nombre de remplissages inclus dans le pack (3, 6 ou 9 — contrainte
    # appliquée côté modèle via une validation `inclusion`).
    add_column :products, :nb_remplissages, :integer, null: true
  end
end
