# ============================================================
# Migration — Table générique de réglages du site
# Un enregistrement = un réglage (clé/valeur).
# Permet à Syam de modifier des réglages globaux (ex : URL de
# la dernière vidéo TikTok) sans qu'on ait à toucher au code.
# ============================================================
class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      # Identifiant unique du réglage (ex : "tiktok_latest_url")
      # On utilise une string plutôt qu'un enum pour rester souple.
      t.string :key, null: false

      # Valeur stockée — text pour accepter des URLs longues ou
      # plus tard du contenu plus volumineux.
      t.text :value

      t.timestamps
    end

    # Index unique sur la clé : on ne veut qu'un seul enregistrement
    # par réglage, et la lecture par clé doit être instantanée.
    add_index :site_settings, :key, unique: true
  end
end
