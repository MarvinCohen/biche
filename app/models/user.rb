class User < ApplicationRecord
  # Devise gère l'authentification (email + mot de passe + récupération)
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # ============================================================
  # SCOPES — filtres réutilisables
  # ============================================================

  # Clientes uniquement (exclut Syam qui a admin: true)
  scope :clientes, -> { where(admin: false) }

  # ============================================================
  # ASSOCIATIONS — une cliente a plusieurs réservations, etc.
  # ============================================================
  has_many :bookings, dependent: :destroy           # Ses réservations
  has_one  :fidelite_card, dependent: :destroy      # Sa carte fidélité (1 seule)
  has_many :orders, dependent: :destroy             # Ses commandes shop
  has_many :messages, dependent: :destroy           # Ses messages/notifications

  # ============================================================
  # VALIDATIONS — champs obligatoires côté modèle
  # ============================================================
  validates :first_name, presence: true
  validates :last_name,  presence: true

  # ============================================================
  # CALLBACKS — actions automatiques à la création du compte
  # ============================================================

  # Crée automatiquement une carte fidélité vide à l'inscription
  after_create :create_fidelite_card_if_absent

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Retourne le nom complet de la cliente (ex: "Marie Lefèvre")
  def full_name
    "#{first_name} #{last_name}"
  end

  # Retourne la première lettre du prénom pour l'avatar
  def initiale
    first_name.to_s.first.upcase
  end

  # Retourne le prochain rendez-vous à venir (confirmé OU en attente)
  # On inclut "en_attente" car la réservation est prise, juste pas encore validée par Syam
  def prochain_rdv
    bookings.where(statut: ['confirme', 'en_attente']).where('date >= ?', Date.today).order(:date, :heure).first
  end

  private

  # Crée la carte fidélité avec 0 points si elle n'existe pas encore
  def create_fidelite_card_if_absent
    create_fidelite_card(points: 0, visites: 0, recompenses_utilisees: 0) unless fidelite_card
  end
end
