class CarteTransaction < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  # Pluralisation custom — la table s'appelle cartes_cadeaux, pas carte_cadeaus
  belongs_to :carte_cadeau, class_name: 'CarteCadeau',
             foreign_key: 'carte_cadeau_id'

  belongs_to :booking, optional: true

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :montant_cents, presence: true, numericality: { greater_than: 0 }
end
