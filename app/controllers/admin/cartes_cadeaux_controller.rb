class Admin::CartesCadeauxController < Admin::BaseController
  # ============================================================
  # Gestion des cartes cadeaux — interface admin Syam
  # Syam peut consulter toutes les cartes, scanner un code,
  # voir le solde restant et déduire un montant lors d'un soin.
  # ============================================================

  before_action :set_carte, only: [:show, :deduire]

  # GET /admin/cartes_cadeaux
  # Liste toutes les cartes actives, puis les épuisées
  def index
    @cartes_actives  = CarteCadeau.actives.recentes.includes(:order)
    @cartes_epuisees = CarteCadeau.epuisees.recentes.includes(:order)
  end

  # GET /admin/cartes_cadeaux/scanner?code=BICHE-XXXX-XXXX
  # Page de recherche par code — Syam tape ou scanne le QR code
  def scanner
    code = params[:code].to_s.strip.upcase
    if code.present?
      @carte = CarteCadeau.find_by(code: code)
      # Si aucune carte trouvée, on affiche un message d'erreur dans la vue
      @erreur = "Aucune carte trouvée pour ce code." unless @carte
    end
  end

  # GET /admin/cartes_cadeaux/:id
  # Fiche complète d'une carte : solde, historique, formulaire de déduction
  def show
    @transactions = @carte.carte_transactions.order(created_at: :desc)
  end

  # POST /admin/cartes_cadeaux/:id/deduire
  # Déduit un montant du solde de la carte après utilisation par la cliente
  def deduire
    montant_euros = params[:montant_euros].to_f
    description   = params[:description].to_s.strip

    # Validation du montant saisi
    if montant_euros <= 0
      redirect_to admin_carte_cadeau_path(@carte),
                  alert: "Le montant doit être supérieur à 0."
      return
    end

    montant_cents = (montant_euros * 100).round

    if montant_cents > @carte.solde_cents
      redirect_to admin_carte_cadeau_path(@carte),
                  alert: "Solde insuffisant. Solde disponible : #{@carte.solde_euros}€"
      return
    end

    # Effectuer la déduction (crée une transaction et met à jour le solde)
    @carte.deduire(
      montant_cents: montant_cents,
      description:   description.presence || "Soin Biche."
    )

    solde_restant = @carte.reload.solde_euros
    message = if @carte.active?
      "#{montant_euros.to_i}€ déduits. Solde restant : #{solde_restant}€"
    else
      "#{montant_euros.to_i}€ déduits. Carte épuisée."
    end

    redirect_to admin_carte_cadeau_path(@carte), notice: message
  end

  private

  def set_carte
    @carte = CarteCadeau.find(params[:id])
  end
end
