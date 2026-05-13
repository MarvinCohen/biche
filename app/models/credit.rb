# ============================================================
# Credit
#
# Représente le droit à N retouches de remplissage gratuites,
# attribué à une cliente après l'achat d'un pack.
#
# Exemple : Marie achète un "Pack 6 remplissages — Volume léger" :
#   → 1 Credit créé avec nb_total=6, nb_restant=6, prestation=Volume léger.
#   À chaque RDV de retouche Volume léger qu'elle utilise sur ce crédit,
#   nb_restant est décrémenté de 1.
#
# Le crédit expire après `nb_remplissages` mois (cf. OrdersController).
# ============================================================
class Credit < ApplicationRecord
  # ============================================================
  # ASSOCIATIONS
  # ============================================================

  belongs_to :user
  belongs_to :order
  belongs_to :prestation  # La pose (catégorie 'extensions') à laquelle le crédit est rattaché

  # Bookings ayant utilisé ce crédit (utile pour l'historique d'utilisation)
  has_many :bookings, dependent: :nullify

  # ============================================================
  # VALIDATIONS
  # ============================================================

  validates :nb_total,        presence: true, numericality: { greater_than: 0 }
  validates :nb_restant,      presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date_expiration, presence: true

  # ============================================================
  # SCOPES
  # ============================================================

  # Crédits encore utilisables : il en reste ET ils ne sont pas expirés.
  # Utilisé partout (espace cliente, recherche de crédit applicable au booking).
  scope :actifs, -> {
    where('nb_restant > 0 AND date_expiration >= ?', Date.today)
  }

  # Tri FIFO : on consomme d'abord les crédits qui expirent le plus tôt
  # (logique cliente — éviter qu'un crédit expire alors qu'on en utilise un autre).
  scope :par_expiration_proche, -> { order(:date_expiration) }

  # ============================================================
  # MÉTHODES MÉTIER
  # ============================================================

  # True si le crédit est applicable à une prestation donnée.
  # Logique : la prestation doit être une RETOUCHE dont le nom contient
  # le nom de la pose de référence (convention : "Remplissage Volume léger — 2 sem"
  # contient "Volume léger").
  # Fragile au renommage des prestations — à terme on pourra ajouter une
  # colonne `pose_id` sur les retouches pour un lien explicite.
  def applicable_a?(prestation_cible)
    return false unless prestation_cible
    return false unless prestation_cible.categorie == 'retouche'
    # Comparaison insensible à la casse pour tolérer "Volume Léger" vs "volume léger"
    prestation_cible.nom.downcase.include?(self.prestation.nom.downcase)
  end

  # Consomme un remplissage du crédit.
  # Lève une exception si le crédit est épuisé ou expiré — appelé uniquement
  # dans des contextes où l'on sait que le crédit est actif (cf. Admin::BookingsController#terminer).
  def utiliser!
    raise "Crédit épuisé" if nb_restant <= 0
    raise "Crédit expiré" if expire?
    decrement!(:nb_restant)
  end

  # Restitue un remplissage au crédit (utilisé en cas d'annulation d'un RDV
  # qui avait consommé le crédit). Borné à nb_total pour éviter les bugs.
  def restituer!
    return if nb_restant >= nb_total
    increment!(:nb_restant)
  end

  # True si la date d'expiration est passée
  def expire?
    date_expiration < Date.today
  end

  # True si plus aucun remplissage disponible
  def epuise?
    nb_restant <= 0
  end

  # Affichage condensé : "3/6 restants" pour la vue espace cliente
  def affichage_restant
    "#{nb_restant}/#{nb_total}"
  end
end
