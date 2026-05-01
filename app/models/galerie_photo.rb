class GaleriePhoto < ApplicationRecord
  # ============================================================
  # Active Storage — une ou deux photos par item
  # :image       → photo principale (ou photo "avant" pour les avant/après)
  # :image_apres → photo "après" — uniquement pour la catégorie avant-apres
  # ============================================================
  has_one_attached :image
  has_one_attached :image_apres

  # ============================================================
  # Validations
  # ============================================================
  # La légende est obligatoire (affiché sur la photo)
  validates :legende,   presence: true
  # La catégorie doit être l'une des valeurs reconnues par le filtre JS
  validates :categorie, presence: true,
                        inclusion: { in: %w[cil-a-cil volume rehaussement sourcils avant-apres] }
  # La taille contrôle la hauteur de la case dans la grille masonry
  validates :taille,    inclusion: { in: %w[tall medium short] }

  # ============================================================
  # Scopes
  # ============================================================
  # Toutes les photos triées par position pour l'affichage dans la galerie
  scope :ordonnes, -> { order(:position) }

  # Préchargement des images pour éviter les N+1 queries
  # On précharge les deux attachments en même temps
  scope :avec_image, -> { with_attached_image.with_attached_image_apres }

  # ============================================================
  # Constantes — valeurs autorisées pour les selects dans les formulaires
  # ============================================================
  CATEGORIES = [
    ['Cil à cil',    'cil-a-cil'],
    ['Volume',       'volume'],
    ['Rehaussement', 'rehaussement'],
    ['Sourcils',     'sourcils'],
    ['Avant / Après','avant-apres']
  ].freeze

  TAILLES = [
    ['Grande',  'tall'],
    ['Moyenne', 'medium'],
    ['Petite',  'short']
  ].freeze
end
