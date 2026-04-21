class Product < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  has_many :orders, dependent: :restrict_with_error  # On ne supprime pas un produit commandé

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :nom,          presence: true
  validates :prix_cents,   presence: true, numericality: { greater_than: 0 }
  validates :type_produit, presence: true

  # Types de produits disponibles dans le shop (correspond aux 3 sections de la maquette)
  TYPES = %w[carte_cadeau pack routine].freeze
  validates :type_produit, inclusion: { in: TYPES }

  # ============================================================
  # SCOPES
  # ============================================================

  # Uniquement les produits en vente
  scope :actifs, -> { where(actif: true) }

  # Filtrer par type (pour les onglets du shop)
  scope :cartes_cadeaux, -> { where(type_produit: 'carte_cadeau') }
  scope :packs,          -> { where(type_produit: 'pack') }
  scope :routine,        -> { where(type_produit: 'routine') }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Convertit les centimes en euros pour l'affichage
  def prix_euros
    prix_cents / 100.0
  end
end
