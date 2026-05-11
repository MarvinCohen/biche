class Video < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================

  # Miniature uploadée par Syam (screenshot du reel Instagram)
  has_one_attached :miniature

  # Fichier vidéo MP4 téléchargé depuis Instagram — joué directement dans la card
  has_one_attached :video_file

  # ============================================================
  # VALIDATIONS
  # ============================================================

  validates :titre, presence: true
  validates :url,   presence: true

  # ============================================================
  # SCOPES
  # ============================================================

  # Vidéos visibles publiquement, triées par position
  scope :actives,   -> { where(actif: true).order(:position) }

  # Toutes les vidéos triées par position (pour l'admin)
  scope :ordonnes,  -> { order(:position) }

  # Préchargement de la miniature et du fichier vidéo — évite N+1 dans les listes
  scope :avec_miniature, -> { with_attached_miniature.with_attached_video_file }

  # ============================================================
  # CONSTANTES
  # ============================================================

  # Tags disponibles — correspondent aux catégories de prestations
  TAGS = [
    ['Extensions cils', 'extensions'],
    ['Rehaussement',    'rehaussement'],
    ['Sourcils',        'sourcils'],
    ['Autre',           'autre']
  ].freeze
end
