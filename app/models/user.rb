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
  has_one  :fidelite_card, dependent: :destroy     # Sa carte fidélité (1 seule)
  # Ordre important : les `credits` doivent être déclarés AVANT les `orders` car
  # un Credit a une FK NOT NULL vers Order. Si on détruit un User, Rails respecte
  # l'ordre de déclaration pour `dependent: :destroy` → les credits partent en
  # premier, ce qui libère ensuite la suppression des orders sans violation FK.
  has_many :credits, dependent: :destroy            # Ses crédits de remplissage (issus de packs)
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

  # Crédits encore utilisables (non épuisés, non expirés), triés par expiration
  # la plus proche pour consommation FIFO. Helper utilisé partout (espace cliente
  # + formulaire de booking) — évite de répéter le scope.
  def credits_actifs
    credits.actifs.par_expiration_proche
  end

  # Cherche un crédit actif applicable à la prestation donnée (ex: retouche
  # Volume léger → crédit Volume léger). Retourne nil si aucun.
  # Utilisé côté formulaire de booking pour proposer "Utiliser un crédit".
  def credit_applicable(prestation)
    return nil unless prestation
    credits_actifs.includes(:prestation).find { |c| c.applicable_a?(prestation) }
  end

  private

  # Crée la carte fidélité avec 0 points si elle n'existe pas encore
  def create_fidelite_card_if_absent
    create_fidelite_card(points: 0, visites: 0, recompenses_utilisees: 0) unless fidelite_card
  end
end
