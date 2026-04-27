class FideliteCard < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================

  # Chaque carte fidélité appartient à une seule cliente
  belongs_to :user

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :points,               numericality: { greater_than_or_equal_to: 0 }
  validates :visites,              numericality: { greater_than_or_equal_to: 0 }
  validates :recompenses_utilisees, numericality: { greater_than_or_equal_to: 0 }

  # ============================================================
  # CONSTANTES — règles du programme fidélité
  # ============================================================

  # Nombre de visites nécessaires pour obtenir une pose offerte
  VISITES_POUR_RECOMPENSE = 10

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Nombre de points actifs dans le cycle en cours (modulo 10)
  # Ex: 4 visites → 4 points actifs sur 10
  def points_cycle_actuel
    visites % VISITES_POUR_RECOMPENSE
  end

  # Nombre de points restants avant la prochaine récompense
  # Ex: 4 points → encore 6 visites
  def points_restants
    VISITES_POUR_RECOMPENSE - points_cycle_actuel
  end

  # Pourcentage de progression dans le cycle actuel (pour la barre de progression)
  # Ex: 4/10 → 40.0
  def progression_pourcent
    (points_cycle_actuel.to_f / VISITES_POUR_RECOMPENSE * 100).round(1)
  end

  # Ajoute une visite et crédite un point (appelé après chaque soin terminé)
  def ajouter_visite!
    increment!(:visites)
    increment!(:points)
  end

  # Vérifie si la cliente a droit à une récompense (10 visites atteintes)
  # Utilisé dans les vues espace cliente pour afficher le badge "Pose offerte"
  def recompense_disponible?
    visites >= VISITES_POUR_RECOMPENSE && (visites / VISITES_POUR_RECOMPENSE) > recompenses_utilisees
  end

  # Marque une récompense comme utilisée (ex: quand Syam offre la pose)
  # Incrémente recompenses_utilisees pour ne pas re-déclencher la récompense
  def utiliser_recompense!
    raise "Aucune récompense disponible" unless recompense_disponible?
    increment!(:recompenses_utilisees)
  end
end
