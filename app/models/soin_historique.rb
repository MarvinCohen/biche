class SoinHistorique < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================

  # Un historique de soin est toujours lié à une réservation
  belongs_to :booking

  # Accès pratique à la cliente via la réservation
  delegate :user, to: :booking

  # ============================================================
  # VALIDATIONS
  # ============================================================

  # La note de Syam est le seul champ obligatoire
  # Les détails techniques (courbure, longueur...) peuvent être complétés progressivement
  validates :booking_id, uniqueness: true  # Un seul historique par réservation

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Résumé lisible des paramètres techniques pour l'espace cliente
  # Ex: "Courbure C · 11-13mm · 0.07mm · Volume 2D"
  def resume_technique
    parts = []
    parts << "Courbure #{courbure}"    if courbure.present?
    parts << longueur                   if longueur.present?
    parts << epaisseur                  if epaisseur.present?
    parts << technique                  if technique.present?
    parts.join(' · ')
  end
end
