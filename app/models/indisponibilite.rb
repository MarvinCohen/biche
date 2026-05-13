class Indisponibilite < ApplicationRecord
  # ============================================================
  # Modèle Indisponibilite — Créneaux bloqués par Syam
  # Peut couvrir une ou plusieurs journées consécutives.
  # Ex: pause déjeuner un jour précis, ou congé sur toute une semaine.
  # ============================================================

  # ---- VALIDATIONS ----

  validates :date_debut, presence: true
  validates :date_fin,   presence: true
  validates :heure_debut, presence: true
  validates :heure_fin,   presence: true

  # date_fin doit être >= date_debut
  validate :fin_apres_debut_date

  # heure_fin doit être > heure_debut (uniquement si la plage est sur un seul jour)
  validate :heure_fin_coherente

  # ---- SCOPES ----

  # Indisponibilités futures ou en cours (triées par date de début)
  scope :a_venir, -> { where('date_fin >= ?', Date.today).order(:date_debut, :heure_debut) }

  # ---- MÉTHODES ----

  # Vérifie si une date donnée tombe dans la plage date_debut..date_fin
  def couvre_le_jour?(date)
    date >= date_debut && date <= date_fin
  end

  # Affiche la plage de dates :
  # - Un seul jour → "lundi 28 avril"
  # - Plusieurs jours → "28 avril → 2 mai"
  def plage_dates
    if date_debut == date_fin
      I18n.l(date_debut, format: "%-d %B %Y")
    else
      "#{I18n.l(date_debut, format: '%-d %B')} → #{I18n.l(date_fin, format: '%-d %B %Y')}"
    end
  end

  # Affiche la plage horaire : "12h00 → 14h00"
  def plage_horaire
    "#{heure_debut.strftime('%Hh%M')} → #{heure_fin.strftime('%Hh%M')}"
  end

  # Nombre de jours couverts (1 si même jour)
  def nb_jours
    (date_fin - date_debut).to_i + 1
  end

  # Indique si l'indispo couvre la journée entière (convention : 00:00 → 23:59)
  # Utilisé pour griser le jour entier dans le calendrier client.
  def jour_entier?
    return false if heure_debut.blank? || heure_fin.blank?
    heure_debut.hour == 0 && heure_debut.min == 0 &&
      heure_fin.hour == 23 && heure_fin.min == 59
  end

  # Liste de dates (objets Date) couvertes par des indispos « jour entier »
  # entre `date_debut` et `date_fin` (bornes incluses).
  # Sert au calendrier client pour griser ces jours.
  # Renvoie un tableau de strings "YYYY-MM-DD" (format attendu par le JS).
  def self.dates_jour_entier_entre(date_debut, date_fin)
    # On charge toutes les indispos qui couvrent au moins un jour de l'intervalle
    indispos = where('date_fin >= ? AND date_debut <= ?', date_debut, date_fin)
    dates = []

    indispos.each do |i|
      # On ne s'intéresse qu'aux indispos « jour entier »
      next unless i.jour_entier?

      # On itère sur chaque jour couvert par l'indispo, en s'arrêtant à `date_fin`
      jour = [i.date_debut, date_debut].max
      derniere = [i.date_fin, date_fin].min
      while jour <= derniere
        dates << jour.strftime('%Y-%m-%d')
        jour += 1
      end
    end

    # Dédoublonnage au cas où deux indispos couvriraient les mêmes jours
    dates.uniq
  end

  private

  # date_fin >= date_debut
  def fin_apres_debut_date
    return unless date_debut.present? && date_fin.present?
    errors.add(:date_fin, "doit être égale ou après la date de début") if date_fin < date_debut
  end

  # heure_fin > heure_debut — pertinent uniquement si on est sur le même jour
  # Sur plusieurs jours, les heures s'appliquent chaque jour (ex: 12h-14h chaque jour)
  def heure_fin_coherente
    return unless heure_debut.present? && heure_fin.present?

    debut_s = heure_debut.hour * 3600 + heure_debut.min * 60
    fin_s   = heure_fin.hour   * 3600 + heure_fin.min   * 60

    errors.add(:heure_fin, "doit être après l'heure de début") if fin_s <= debut_s
  end
end
