class Message < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  belongs_to :user  # La cliente destinataire du message

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :titre,        presence: true
  validates :type_message, presence: true

  # Types de messages (correspond aux icônes dans la maquette espace cliente)
  TYPES = %w[anniversaire promo news rappel_rdv].freeze
  validates :type_message, inclusion: { in: TYPES }

  # ============================================================
  # SCOPES
  # ============================================================

  # Messages non lus uniquement
  # On inclut lu: nil car les messages créés sans valeur explicite ont lu = NULL en base
  # where(lu: false) seul raterait ces enregistrements → on couvre false ET nil
  scope :non_lus, -> { where(lu: [false, nil]) }

  # Du plus récent au plus ancien
  scope :recents, -> { order(created_at: :desc) }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Marque le message comme lu
  def marquer_comme_lu!
    update!(lu: true)
  end
end
