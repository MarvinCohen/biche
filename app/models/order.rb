class Order < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  belongs_to :user     # La cliente qui commande
  belongs_to :product  # Le produit commandé

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :statut,       presence: true
  validates :montant_cents, presence: true, numericality: { greater_than: 0 }

  # Statuts possibles pour une commande
  STATUTS = %w[en_attente paye annule rembourse].freeze
  validates :statut, inclusion: { in: STATUTS }

  # ============================================================
  # SCOPES
  # ============================================================
  scope :payees, -> { where(statut: 'paye') }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Montant en euros pour l'affichage
  def montant_euros
    montant_cents / 100.0
  end

  # Vérifie si c'est une commande de carte cadeau (nécessite email destinataire)
  def carte_cadeau?
    product.type_produit == 'carte_cadeau'
  end
end
