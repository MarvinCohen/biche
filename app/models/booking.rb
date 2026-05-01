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

  # Vérifie qu'aucun RDV ne chevauche la plage horaire de ce booking
  # Un chevauchement existe si : nouveau_début < existant_fin ET nouveau_fin > existant_début
  validate :pas_de_chevauchement

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
  # On utilise .minutes (ActiveSupport) car heure est un objet Time en Rails.
  # Sans .minutes, * 60 ajouterait des secondes brutes, pas des minutes.
  def heure_fin
    heure + prestation.duree_minutes.minutes
  end

  # Formate la date et l'heure pour l'affichage (ex: "Sam. 18 avril 2026 · 12h00")
  def date_heure_formatee
    "#{I18n.l(date, format: :long)} · #{heure.strftime('%Hh%M')}"
  end

  private

  # Vérifie l'absence de chevauchement avec les RDVs existants du même jour
  # On exclut les RDVs annulés et le booking lui-même (pour les modifications futures)
  def pas_de_chevauchement
    # On ne vérifie que si les champs nécessaires sont présents
    return unless date.present? && heure.present? && prestation.present?

    # Convertir en secondes depuis minuit pour éviter les problèmes de date
    # Rails stocke :time avec 2000-01-01, les calculs avec .minutes changent aussi la date
    to_s = ->(t) { t.hour * 3600 + t.min * 60 }

    nouveau_debut_s = to_s.call(heure)
    nouveau_fin_s   = nouveau_debut_s + prestation.duree_minutes * 60

    # Charger tous les RDVs du même jour (hors annulés et hors soi-même)
    Booking.where(date: date)
           .where.not(statut: 'annule')
           .where.not(id: id)
           .includes(:prestation, :user)
           .each do |rdv|
      existant_debut_s = to_s.call(rdv.heure)
      existant_fin_s   = existant_debut_s + rdv.prestation.duree_minutes * 60

      if nouveau_debut_s < existant_fin_s && nouveau_fin_s > existant_debut_s
        heure_fin_fmt = "#{(existant_fin_s / 3600).to_i}h#{(existant_fin_s % 3600 / 60).to_s.rjust(2, '0')}"
        errors.add(:heure, "chevauche le RDV de #{rdv.user.full_name} "\
                           "(#{rdv.heure.strftime('%Hh%M')} → #{heure_fin_fmt})")
        return
      end
    end
  end
end
