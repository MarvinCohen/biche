# ============================================================
# Modèle SiteSetting
# Table clé/valeur pour les réglages globaux du site éditables
# par Syam depuis l'admin (sans déploiement).
#
# Exemple d'usage :
#   SiteSetting.get("some_key")          # lit la valeur d'une clé
#   SiteSetting.set("some_key", "...")   # écrit la valeur
#   SiteSetting.video_setting            # singleton pour la vidéo native
# ============================================================
class SiteSetting < ApplicationRecord
  # ----------------------------------------------------------
  # ACTIVE STORAGE
  # ----------------------------------------------------------

  # Fichier vidéo attaché (MP4 uploadé par Syam depuis l'admin) — utilisé
  # par le réglage de clé "video_latest" pour afficher la dernière vidéo
  # type TikTok directement sur le site (home + galerie) sans dépendre
  # de l'embed TikTok externe.
  # has_one_attached crée la relation Active Storage côté Rails, pas
  # besoin de migration spécifique (les tables `active_storage_*` sont
  # déjà installées par le template).
  has_one_attached :video_file

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

  # Helper dédié à la vidéo "dernière TikTok native".
  # Active Storage attache un fichier à une INSTANCE — donc on a
  # besoin d'un enregistrement précis pour y rattacher le MP4.
  # On utilise la clé "video_latest" comme singleton :
  #   - find_or_create_by garantit qu'on a toujours un objet (créé
  #     au premier appel, retrouvé ensuite)
  #   - le champ `value` sert pour la légende texte de la vidéo
  #     (ex: "Pose volume 5D") — affichée sous le player.
  def self.video_setting
    find_or_create_by(key: "video_latest")
  end
end
