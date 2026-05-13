class Product < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  has_many :orders, dependent: :restrict_with_error  # On ne supprime pas un produit commandé

  # Photo du produit — gérée via Active Storage
  has_one_attached :photo

  # Lien optionnel vers la prestation de pose (uniquement pour les packs).
  # `optional: true` car les autres types de produits (cartes cadeaux,
  # routine) n'ont pas de prestation associée.
  belongs_to :prestation, optional: true

  # ============================================================
  # VALIDATIONS — communes à tous les types
  # ============================================================
  validates :nom,          presence: true
  validates :prix_cents,   presence: true, numericality: { greater_than: 0 }
  validates :type_produit, presence: true

  # Types de produits disponibles dans le shop (correspond aux 3 sections de la maquette)
  TYPES = %w[carte_cadeau pack routine].freeze
  validates :type_produit, inclusion: { in: TYPES }

  # ============================================================
  # VALIDATIONS CONDITIONNELLES — spécifiques aux packs
  # ============================================================

  # Quantités autorisées pour un pack de remplissages.
  # Centralisé en constante pour pouvoir l'utiliser dans la validation
  # ET dans le formulaire admin (select des options).
  NB_REMPLISSAGES_AUTORISES = [3, 6, 9].freeze

  # Un pack DOIT être lié à une prestation de pose (pour savoir quelle
  # pose il concerne — Cil à cil, Volume léger, etc.).
  validates :prestation_id, presence: true, if: :pack?

  # Un pack DOIT avoir un nombre de remplissages parmi 3 / 6 / 9.
  # `allow_nil: false` est implicite avec `inclusion` — un nb manquant
  # échoue donc la validation, ce qu'on veut.
  validates :nb_remplissages,
            inclusion: { in: NB_REMPLISSAGES_AUTORISES,
                         message: "doit être 3, 6 ou 9" },
            if: :pack?

  # ============================================================
  # SCOPES
  # ============================================================

  # Uniquement les produits en vente
  scope :actifs, -> { where(actif: true) }

  # Filtrer par type (pour les onglets du shop)
  scope :cartes_cadeaux, -> { where(type_produit: 'carte_cadeau') }
  scope :packs,          -> { where(type_produit: 'pack') }
  scope :routine,        -> { where(type_produit: 'routine') }

  # Tri des packs pour affichage cohérent : d'abord par pose (ordre alpha
  # des noms de prestation), puis par nombre de remplissages croissant.
  # Utilise un LEFT JOIN sur prestations pour pouvoir trier par leur nom.
  scope :par_pose, -> {
    joins('LEFT JOIN prestations ON prestations.id = products.prestation_id')
      .order('prestations.nom ASC, products.nb_remplissages ASC')
  }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Convertit les centimes en euros pour l'affichage
  def prix_euros
    prix_cents / 100.0
  end

  # Helper booléen — true si ce produit est un pack de remplissages.
  # Utilisé par les validations conditionnelles ci-dessus.
  def pack?
    type_produit == 'pack'
  end
end
