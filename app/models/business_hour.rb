class BusinessHour < ApplicationRecord
  # ============================================================
  # Modèle BusinessHour — Horaires d'ouverture hebdomadaires
  #
  # Une ligne par jour de la semaine (7 lignes au total).
  # Syam édite ces horaires depuis l'admin.
  #
  # Méthode clé : `creneaux_pour(date, duree_minutes)` → renvoie
  # la liste des créneaux théoriques (sans tenir compte des RDVs
  # existants ni des indisponibilités, qui restent dans le controller).
  # ============================================================

  # ---- CONSTANTES ----

  # Noms français des jours, indexés selon `Date#wday` (0 = dimanche … 6 = samedi)
  # Utilisé dans la vue admin pour afficher le libellé du jour.
  JOURS_FR = {
    0 => "Dimanche",
    1 => "Lundi",
    2 => "Mardi",
    3 => "Mercredi",
    4 => "Jeudi",
    5 => "Vendredi",
    6 => "Samedi"
  }.freeze

  # ---- VALIDATIONS ----

  # `day_of_week` doit exister, être entre 0 et 6, et unique en base
  validates :day_of_week,
            presence: true,
            inclusion: { in: 0..6 },
            uniqueness: true

  # Les heures d'ouverture sont obligatoires même si le jour est fermé
  # (on garde les valeurs au cas où Syam rouvre — pas de perte d'info)
  validates :heure_debut, presence: true
  validates :heure_fin,   presence: true

  # `pas_minutes` doit être un entier positif raisonnable
  # (15 min mini = créneaux très serrés ; 240 max = 4h, déjà très large)
  validates :pas_minutes,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 15, less_than_or_equal_to: 240 }

  # heure_fin > heure_debut
  validate :fin_apres_debut

  # Si une seule heure de pause est renseignée, c'est incohérent → on exige les deux ou aucune
  validate :pause_coherente

  # ---- SCOPES ----

  # Tous les jours, triés du lundi (1) au dimanche (0)
  # On utilise SQL pour pousser dimanche en dernier (convention française).
  scope :triee_lundi_premier, -> {
    order(Arel.sql("CASE WHEN day_of_week = 0 THEN 7 ELSE day_of_week END"))
  }

  # ---- MÉTHODES DE CLASSE ----

  # Récupère le BusinessHour correspondant à une date donnée.
  # Renvoie nil si aucun enregistrement (cas de seed incomplet).
  def self.pour_date(date)
    find_by(day_of_week: date.wday)
  end

  # Génère les créneaux disponibles pour une date donnée et une durée de prestation.
  # Renvoie un tableau de `Time` (date du jour + heure du créneau).
  #
  # Exclut :
  # - les créneaux qui dépasseraient `heure_fin` (créneau + durée > fermeture)
  # - les créneaux qui chevaucheraient la pause déjeuner
  #
  # Cette méthode ne tient PAS compte des RDVs existants ni des indisponibilités :
  # cette logique reste dans `BookingsController#creneaux` (séparation des responsabilités).
  def self.creneaux_pour(date, duree_minutes)
    horaire = pour_date(date)

    # Pas d'horaire en base OU jour fermé → aucun créneau
    return [] if horaire.nil? || !horaire.ouvert

    horaire.creneaux(duree_minutes)
  end

  # ---- MÉTHODES D'INSTANCE ----

  # Nom français du jour (ex : "Mardi")
  def nom_jour
    JOURS_FR[day_of_week]
  end

  # Génère la liste des créneaux pour ce jour, étant donné une durée de prestation.
  # Renvoie un tableau de `Time` (date du jour 1er janvier 2000 + heure du créneau).
  # On utilise une date neutre car seules les heures comptent pour l'affichage.
  def creneaux(duree_minutes)
    return [] unless ouvert

    # Conversion en secondes depuis minuit — évite les pièges de TimeZone et de Date
    debut_s = secondes_depuis_minuit(heure_debut)
    fin_s   = secondes_depuis_minuit(heure_fin)
    pas_s   = pas_minutes * 60
    duree_s = duree_minutes * 60

    # Plage de pause (nil si pas de pause configurée)
    pause_debut_s = pause_debut.present? ? secondes_depuis_minuit(pause_debut) : nil
    pause_fin_s   = pause_fin.present?   ? secondes_depuis_minuit(pause_fin)   : nil

    creneaux = []
    creneau_s = debut_s

    # Boucle : tant qu'un créneau peut tenir avant la fermeture (créneau + durée ≤ heure_fin)
    while creneau_s + duree_s <= fin_s
      # Vérifier si le créneau (créneau_s..créneau_s+duree_s) chevauche la pause déjeuner
      chevauche_pause = pause_debut_s && pause_fin_s &&
                        creneau_s < pause_fin_s &&
                        (creneau_s + duree_s) > pause_debut_s

      creneaux << seconds_to_time(creneau_s) unless chevauche_pause
      creneau_s += pas_s
    end

    creneaux
  end

  # Affichage compact des horaires (utile pour la vue admin)
  # Ex : "9h00 → 18h00" ou "Fermé"
  def horaires_affichage
    return "Fermé" unless ouvert
    "#{heure_debut.strftime('%-Hh%M')} → #{heure_fin.strftime('%-Hh%M')}"
  end

  private

  # Convertit un `Time` (Rails :time column) en secondes depuis minuit.
  # Pratique pour comparer deux horaires sans se soucier de la date associée.
  def self.secondes_depuis_minuit(t)
    t.hour * 3600 + t.min * 60
  end

  # Idem en instance (les méthodes privées de classe ne sont pas accessibles depuis l'instance)
  def secondes_depuis_minuit(t)
    self.class.secondes_depuis_minuit(t)
  end

  # Convertit un nombre de secondes depuis minuit en `Time` (date neutre 2000-01-01)
  # On utilise une date fixe pour éviter les soucis de fuseau horaire / DST.
  def seconds_to_time(s)
    Time.new(2000, 1, 1, s / 3600, (s % 3600) / 60)
  end

  # Validation : heure_fin doit être strictement après heure_debut
  def fin_apres_debut
    return unless heure_debut.present? && heure_fin.present?

    debut_s = self.class.secondes_depuis_minuit(heure_debut)
    fin_s   = self.class.secondes_depuis_minuit(heure_fin)

    errors.add(:heure_fin, "doit être après l'heure de début") if fin_s <= debut_s
  end

  # Validation : pause_debut et pause_fin doivent être tous deux renseignés (ou tous deux vides)
  # ET pause_fin doit être après pause_debut, ET la pause doit être dans la plage d'ouverture
  def pause_coherente
    # Cas 1 : aucun des deux renseignés → OK (pas de pause)
    return if pause_debut.blank? && pause_fin.blank?

    # Cas 2 : un seul des deux renseignés → erreur
    if pause_debut.blank? || pause_fin.blank?
      errors.add(:base, "Renseigner les deux heures de pause (début et fin), ou aucune")
      return
    end

    # Cas 3 : les deux renseignés → fin > début
    pd_s = self.class.secondes_depuis_minuit(pause_debut)
    pf_s = self.class.secondes_depuis_minuit(pause_fin)

    errors.add(:pause_fin, "doit être après le début de la pause") if pf_s <= pd_s

    # Cas 4 : la pause doit être incluse dans la plage d'ouverture
    if heure_debut.present? && heure_fin.present?
      ouv_s = self.class.secondes_depuis_minuit(heure_debut)
      fer_s = self.class.secondes_depuis_minuit(heure_fin)
      if pd_s < ouv_s || pf_s > fer_s
        errors.add(:base, "La pause doit être comprise dans les heures d'ouverture")
      end
    end
  end
end
