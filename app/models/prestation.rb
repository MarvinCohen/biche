class Prestation < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================

  # On bloque la suppression si des réservations existent pour cette prestation
  has_many :bookings, dependent: :restrict_with_error

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :nom,           presence: true
  validates :prix_cents,    presence: true, numericality: { greater_than: 0 }
  validates :duree_minutes, presence: true, numericality: { greater_than: 0 }
  validates :categorie,     presence: true

  # Valeurs acceptées pour la catégorie
  # extensions   → poses complètes (cil à cil, volume, manga...)
  # retouche     → remplissages 2 ou 3 semaines
  # rehaussement → rehaussement seul ou avec teinture
  # depose       → dépose simple ou extérieure
  CATEGORIES = %w[extensions retouche rehaussement depose].freeze
  validates :categorie, inclusion: { in: CATEGORIES }

  # ============================================================
  # SCOPES — requêtes fréquentes prêtes à l'emploi
  # ============================================================

  # Uniquement les prestations visibles par les clientes
  scope :disponibles, -> { where(disponible: true) }

  # Tri alphabétique par défaut
  scope :par_nom, -> { order(:nom) }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Convertit les centimes en euros pour l'affichage
  # Ex: 6500 → 65.0 (affiché "65€" dans les vues)
  def prix_euros
    prix_cents / 100.0
  end

  # Formate la durée de façon lisible
  # Ex: 150 minutes → "2h30", 60 minutes → "1h"
  def duree_formatee
    heures  = duree_minutes / 60
    minutes = duree_minutes % 60
    minutes.zero? ? "#{heures}h" : "#{heures}h#{minutes.to_s.rjust(2, '0')}"
  end
end
