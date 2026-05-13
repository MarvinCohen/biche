class Booking < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  belongs_to :user        # La cliente qui réserve
  belongs_to :prestation  # Le soin réservé

  # Optionnel : crédit utilisé pour payer ce RDV (à la place de Stripe).
  # Renseigné uniquement si la cliente a utilisé un de ses crédits de pack
  # pour réserver une retouche. Quand le RDV passe en `termine`, on décrémente
  # `credit.nb_restant` (cf. Admin::BookingsController#terminer).
  belongs_to :credit, optional: true

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

  # Modes de paiement/garantie disponibles.
  # - acompte   : paiement de 30% du prix via Stripe au moment de la résa
  # - empreinte : empreinte CB sans débit (à implémenter avec SetupIntent)
  # - credit    : la cliente utilise un crédit issu d'un pack (pas de paiement immédiat)
  MODES_PAIEMENT = %w[acompte empreinte credit].freeze
  validates :mode_paiement, inclusion: { in: MODES_PAIEMENT }

  # Vérifie qu'aucun RDV ne chevauche la plage horaire de ce booking
  # Un chevauchement existe si : nouveau_début < existant_fin ET nouveau_fin > existant_début
  validate :pas_de_chevauchement

  # Vérifie que le créneau tombe dans les horaires d'ouverture (BusinessHour)
  # → jour ouvert, dans la plage heure_debut..heure_fin, et hors pause déjeuner
  # Validation bypassée si `skip_business_hours_validation = true` (création admin)
  validate :dans_les_horaires_ouverture, unless: :skip_business_hours_validation

  # Attribut virtuel (non persisté) — l'admin peut le setter pour forcer un créneau
  # hors horaires (ex : amie qui passe en dehors des heures normales).
  attr_accessor :skip_business_hours_validation

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

  # True si le RDV a été payé avec un crédit (au lieu de Stripe).
  # Utilisé pour adapter l'affichage (ex: pas de bouton "payer le solde").
  def paye_avec_credit?
    credit_id.present?
  end

  private

  # Vérifie que le créneau respecte les horaires d'ouverture définis par Syam
  # dans la table `business_hours`. Trois cas d'erreur :
  # 1. Jour fermé (ouvert: false) → "fermé ce jour-là"
  # 2. Créneau hors plage [heure_debut..heure_fin] → "hors des heures d'ouverture"
  # 3. Créneau chevauche la pause déjeuner → "pendant la pause déjeuner"
  def dans_les_horaires_ouverture
    return unless date.present? && heure.present? && prestation.present?

    # Récupère la configuration du jour de la semaine concerné
    bh = BusinessHour.pour_date(date)

    # Pas de config en base → on laisse passer (cas de setup incomplet)
    # Préférable à un blocage strict qui pénaliserait Syam si la table est vide.
    return if bh.nil?

    # Jour fermé → erreur explicite
    unless bh.ouvert
      errors.add(:date, "le salon est fermé le #{bh.nom_jour.downcase}")
      return
    end

    # Conversion en secondes depuis minuit (même logique que ailleurs dans la base)
    to_s = ->(t) { t.hour * 3600 + t.min * 60 }

    debut_s    = to_s.call(heure)
    fin_s      = debut_s + prestation.duree_minutes * 60
    ouverture  = to_s.call(bh.heure_debut)
    fermeture  = to_s.call(bh.heure_fin)

    # Créneau hors plage d'ouverture (commence avant ou finit après)
    if debut_s < ouverture || fin_s > fermeture
      errors.add(:heure,
                 "doit être entre #{bh.heure_debut.strftime('%-Hh%M')} et "\
                 "#{bh.heure_fin.strftime('%-Hh%M')} (durée du soin incluse)")
      return
    end

    # Chevauchement avec la pause déjeuner (si configurée)
    if bh.pause_debut.present? && bh.pause_fin.present?
      pause_debut_s = to_s.call(bh.pause_debut)
      pause_fin_s   = to_s.call(bh.pause_fin)

      if debut_s < pause_fin_s && fin_s > pause_debut_s
        errors.add(:heure,
                   "tombe pendant la pause déjeuner "\
                   "(#{bh.pause_debut.strftime('%-Hh%M')} → #{bh.pause_fin.strftime('%-Hh%M')})")
      end
    end
  end

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
