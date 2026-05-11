# ============================================================
# Modèle SiteSetting
# Table clé/valeur pour les réglages globaux du site éditables
# par Syam depuis l'admin (sans déploiement).
#
# Exemple d'usage :
#   SiteSetting.get("tiktok_latest_url")      # lit la valeur
#   SiteSetting.set("tiktok_latest_url", url) # écrit la valeur
# ============================================================
class SiteSetting < ApplicationRecord
  # ----------------------------------------------------------
  # VALIDATIONS
  # ----------------------------------------------------------

  # La clé est obligatoire (sinon on ne peut pas retrouver le réglage)
  # et unique (un seul enregistrement par réglage — index DB en plus).
  validates :key, presence: true, uniqueness: true

  # ----------------------------------------------------------
  # HELPERS DE CLASSE
  # ----------------------------------------------------------

  # Lit la valeur du réglage identifié par `key`.
  # Renvoie nil si le réglage n'existe pas encore en base —
  # les vues doivent donc tester la présence avant d'afficher.
  def self.get(key)
    find_by(key: key)&.value
  end

  # Crée ou met à jour le réglage `key` avec la `value` donnée.
  # find_or_initialize_by + save garantit une seule ligne par clé,
  # même si plusieurs admins enregistrent en même temps (grâce
  # aussi à l'index unique en base, qui lèverait une erreur sinon).
  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value
    setting.save
  end
end
