class OrdersController < ApplicationController
  # ============================================================
  # Commandes boutique — cartes cadeaux
  # L'utilisateur doit être connecté pour commander
  # ============================================================
  before_action :authenticate_user!

  # GET /orders/new?montant=65&destinataire_nom=Marie
  # Page de récapitulatif avant paiement — l'utilisateur entre l'email du destinataire
  def new
    @montant_euros    = params[:montant].to_i
    @destinataire_nom = params[:destinataire_nom].to_s.strip

    if @montant_euros < 10
      redirect_to shop_path, alert: "Veuillez sélectionner un montant pour la carte cadeau."
      return
    end

    @produit_carte = Product.actifs.where(type_produit: 'carte_cadeau').first

    unless @produit_carte
      redirect_to shop_path, alert: "Les cartes cadeaux ne sont pas disponibles pour le moment."
      return
    end

    @order = Order.new(
      product:          @produit_carte,
      montant_cents:    @montant_euros * 100,
      destinataire_nom: @destinataire_nom
    )
  end

  # POST /orders
  # Crée l'order en base, ouvre une Stripe Checkout Session, redirige vers Stripe
  def create
    @produit_carte = Product.actifs.where(type_produit: 'carte_cadeau').first

    @order = Order.new(order_params)
    @order.user    = current_user
    @order.product = @produit_carte
    @order.statut  = 'en_attente'  # Sera mis à jour en 'paye' après confirmation Stripe

    unless @order.valid?
      @montant_euros    = @order.montant_cents.to_i / 100
      @destinataire_nom = @order.destinataire_nom.to_s
      render :new, status: :unprocessable_entity
      return
    end

    # Sauvegarder l'order avant de créer la session Stripe
    # (on a besoin de l'ID pour le metadata de la session)
    @order.save!

    begin
      # Créer la Stripe Checkout Session — page de paiement hébergée par Stripe
      session = Stripe::Checkout::Session.create({
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency:     'eur',
            # Montant en centimes, comme Stripe l'attend
            unit_amount:  @order.montant_cents,
            product_data: {
              name:        "Carte cadeau Biche. — #{@order.montant_cents / 100}€",
              description: @order.destinataire_nom.present? ? "Pour #{@order.destinataire_nom}" : "Carte cadeau Biche."
            }
          },
          quantity: 1
        }],
        mode: 'payment',
        # Email pré-rempli dans le formulaire Stripe pour l'acheteur
        customer_email: current_user.email,
        # URL de retour après paiement réussi.
        # IMPORTANT : on concatène manuellement le placeholder — si on passe session_id
        # comme paramètre Rails, les {} sont encodés en %7B%7D et Stripe ne les remplace pas.
        success_url: "#{success_orders_url}?session_id={CHECKOUT_SESSION_ID}",
        # URL si l'utilisateur annule sur la page Stripe
        cancel_url:  new_order_url(
          montant:          @order.montant_cents / 100,
          destinataire_nom: @order.destinataire_nom
        ),
        # Metadata pour retrouver l'order dans le webhook et la page success
        metadata: { order_id: @order.id }
      })

      # Stocker l'ID de session Stripe pour le retrouver après paiement
      @order.update!(stripe_payment_intent_id: session.id)

      # Rediriger vers la page de paiement Stripe hébergée
      redirect_to session.url, allow_other_host: true

    rescue Stripe::StripeError => e
      # En cas d'erreur Stripe, supprimer l'order créé et afficher l'erreur
      @order.destroy
      @montant_euros    = order_params[:montant_cents].to_i / 100
      @destinataire_nom = order_params[:destinataire_nom].to_s
      @order = Order.new(order_params)
      flash.now[:alert] = "Erreur lors de la connexion au paiement : #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  # GET /orders/success?session_id=cs_xxx
  # Page de confirmation après paiement Stripe réussi
  def success
    # Retrouver la session Stripe pour vérifier le paiement
    stripe_session = Stripe::Checkout::Session.retrieve(params[:session_id])
    @order = Order.find(stripe_session.metadata.order_id)

    # Sécurité — vérifier que c'est bien la commande de l'utilisateur connecté
    unless @order.user == current_user
      redirect_to root_path, alert: "Accès non autorisé."
      return
    end

    if @order.statut == 'en_attente'
      # Cas normal : le webhook n'a pas encore traité (ou est en retard)
      # On met à jour le statut, crée la carte et envoie les emails
      @order.update!(statut: 'paye')
      @order.creer_carte_cadeau!
      envoyer_emails_carte_cadeau(@order)

    elsif @order.statut == 'paye' && @order.cartes_cadeaux.none?
      # Cas de rattrapage : le webhook a mis le statut à 'paye' mais a planté
      # avant de créer la carte (ex: inflection non chargée, erreur BDD).
      # On crée la carte et envoie les emails ici pour ne pas bloquer la cliente.
      Rails.logger.warn "Order ##{@order.id} : statut paye sans carte cadeau — rattrapage depuis orders#success"
      @order.creer_carte_cadeau!
      envoyer_emails_carte_cadeau(@order)

    else
      # Commande déjà traitée complètement (rechargement de page, retour webhook)
      # On affiche juste la page de confirmation sans rien faire
      Rails.logger.info "Order ##{@order.id} : déjà traité, affichage confirmation uniquement"
    end
  end

  # GET /orders/:id
  def show
    @order = Order.find(params[:id])
    unless @order.user == current_user
      redirect_to root_path, alert: "Accès non autorisé."
    end
  end

  private

  def order_params
    params.require(:order).permit(
      :montant_cents,
      :destinataire_nom,
      :destinataire_email
    )
  end

  # Envoie les 3 emails liés à une carte cadeau
  # Factorisé ici pour être appelé depuis success et le rattrapage
  # deliver_now — synchrone, pas besoin de Solid Queue en arrière-plan
  def envoyer_emails_carte_cadeau(order)
    OrderMailer.carte_cadeau_acheteur(order).deliver_now
    OrderMailer.carte_cadeau_destinataire(order).deliver_now
    OrderMailer.carte_cadeau_notif_syam(order).deliver_now
    Rails.logger.info "Order ##{order.id} : 3 emails carte cadeau envoyés"
  end
end
