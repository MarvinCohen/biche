class CarteCadeau < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================
  belongs_to :order
  # Historique de toutes les utilisations de cette carte
  has_many :carte_transactions, dependent: :destroy

  # ============================================================
  # VALIDATIONS
  # ============================================================
  validates :code,                  presence: true, uniqueness: true
  validates :montant_initial_cents, presence: true, numericality: { greater_than: 0 }
  validates :solde_cents,           presence: true, numericality: { greater_than_or_equal_to: 0 }

  # ============================================================
  # SCOPES
  # ============================================================
  scope :actives,   -> { where(active: true) }
  scope :epuisees,  -> { where(active: false) }
  scope :recentes,  -> { order(created_at: :desc) }

  # ============================================================
  # GÉNÉRATION DU CODE UNIQUE
  # ============================================================
  # before_validation (et non before_create) pour que le code soit généré
  # AVANT que Rails vérifie la validation presence: true sur :code.
  # Avec before_create, la validation tournait en premier → code nil → erreur.
  before_validation :generer_code, on: :create

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # Montant initial en euros pour l'affichage
  def montant_initial_euros
    montant_initial_cents / 100.0
  end

  # Solde restant en euros
  def solde_euros
    solde_cents / 100.0
  end

  # Pourcentage du solde restant (pour une barre de progression)
  def pourcentage_restant
    return 0 if montant_initial_cents.zero?
    (solde_cents.to_f / montant_initial_cents * 100).round
  end

  # Déduit un montant de la carte — crée une transaction et met à jour le solde
  # Retourne false si le solde est insuffisant
  def deduire(montant_cents:, description: nil, booking_id: nil)
    return false unless active?
    return false if montant_cents > solde_cents

    # Créer la transaction d'abord (traçabilité)
    carte_transactions.create!(
      montant_cents: montant_cents,
      description:   description,
      booking_id:    booking_id
    )

    # Décrémenter le solde
    nouveau_solde = solde_cents - montant_cents
    update!(
      solde_cents: nouveau_solde,
      # Désactiver la carte si le solde tombe à 0
      active: nouveau_solde > 0
    )

    true
  end

  private

  # Génère un code unique de type BICHE-XXXX-XXXX (8 caractères aléatoires)
  # Boucle jusqu'à trouver un code qui n'existe pas encore en base
  def generer_code
    loop do
      # 8 caractères aléatoires parmi les lettres majuscules et chiffres
      # On évite 0, O, I, 1 pour éviter les confusions à la lecture
      chars = ('A'..'Z').to_a + ('2'..'9').to_a - ['O', 'I']
      partie = Array.new(8) { chars.sample }.join
      # Format : BICHE-XXXX-XXXX
      candidat = "BICHE-#{partie[0..3]}-#{partie[4..7]}"

      # S'assurer que le code n'existe pas déjà
      unless CarteCadeau.exists?(code: candidat)
        self.code = candidat
        break
      end
    end
  end
end
