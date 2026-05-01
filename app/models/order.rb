class Order < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  belongs_to :user     # La cliente qui commande
  belongs_to :product  # Le produit commandé
  has_many   :cartes_cadeaux, class_name: 'CarteCadeau'

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

  # Vérifie si c'est une commande de carte cadeau
  def carte_cadeau?
    product.type_produit == 'carte_cadeau'
  end

  # Crée la CarteCadeau associée après confirmation du paiement
  # Appelé depuis orders#success et le webhook Stripe
  # Idempotent : ne crée rien si une carte existe déjà pour cette commande
  def creer_carte_cadeau!
    return if cartes_cadeaux.exists?

    cartes_cadeaux.create!(
      montant_initial_cents: montant_cents,
      solde_cents:           montant_cents  # Solde initial = montant total
    )
  end
end
