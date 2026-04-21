class Booking < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  belongs_to :user        # La cliente qui réserve
  belongs_to :prestation  # Le soin réservé

  # Chaque réservation peut avoir un détail de soin (rempli après la visite par Syam)
  has_one :soin_historique, dependent: :destroy

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :date,           presence: true
  validates :heure,          presence: true
  validates :statut,         presence: true
  validates :mode_paiement,  presence: true

  # Statuts possibles pour une réservation (cycle de vie complet)
  STATUTS = %w[en_attente confirme annule termine].freeze
  validates :statut, inclusion: { in: STATUTS }

  # Modes de paiement/garantie disponibles (comme dans la maquette)
  MODES_PAIEMENT = %w[acompte empreinte].freeze
  validates :mode_paiement, inclusion: { in: MODES_PAIEMENT }

  # ============================================================
  # SCOPES — filtres fréquents pour les requêtes
  # ============================================================

  # Réservations confirmées uniquement
  scope :confirmees, -> { where(statut: 'confirme') }

  # Réservations à venir (date >= aujourd'hui)
  scope :a_venir, -> { where('date >= ?', Date.today).order(:date, :heure) }

  # Réservations passées (date < aujourd'hui)
  scope :passees, -> { where('date < ?', Date.today).order(date: :desc) }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Calcule le montant de l'acompte (30% du prix de la prestation)
  # Ex: prestation à 80€ → acompte de 24€ (2400 centimes)
  def acompte_calcule_cents
    (prestation.prix_cents * 0.30).round
  end

  # Retourne l'heure de fin calculée à partir de l'heure de début + durée
  def heure_fin
    heure + prestation.duree_minutes * 60
  end

  # Formate la date et l'heure pour l'affichage (ex: "Sam. 18 avril 2026 · 12h00")
  def date_heure_formatee
    "#{I18n.l(date, format: :long)} · #{heure.strftime('%Hh%M')}"
  end
end
