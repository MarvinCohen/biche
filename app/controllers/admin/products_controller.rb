module Admin
  # ============================================================
  # Produits boutique — CRUD complet
  # Syam peut gérer cartes cadeaux, packs et produits routine.
  # ============================================================
  class ProductsController < BaseController

    before_action :set_product,         only: [:edit, :update, :destroy]
    # Charge la liste des poses sélectionnables pour les packs (uniquement
    # les prestations de catégorie "extensions" — c'est ce qui définit
    # le "type de pose" d'un pack de remplissages).
    before_action :set_poses_disponibles, only: [:new, :create, :edit, :update]

    # GET /admin/products — liste groupée par type
    def index
      # Tous les produits (actifs et inactifs) groupés par type, avec photo
      # ET prestation préchargées (évite N+1 quand on affiche la pose des packs).
      @products_par_type = Product
                             .order(:type_produit, :nom)
                             .with_attached_photo
                             .includes(:prestation)
                             .group_by(&:type_produit)
    end

    # GET /admin/products/new — formulaire de création
    def new
      @product = Product.new
      @product.actif = true  # Actif par défaut
    end

    # POST /admin/products — créer un produit
    def create
      @product = Product.new(product_params)

      # Convertir le prix saisi en euros → centimes
      if params[:product][:prix_euros].present?
        @product.prix_cents = (params[:product][:prix_euros].to_f * 100).round
      end

      if @product.save
        redirect_to admin_products_path, notice: "\"#{@product.nom}\" ajouté à la boutique."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/products/:id/edit
    def edit
    end

    # PATCH /admin/products/:id
    def update
      if params[:product][:prix_euros].present?
        params[:product][:prix_cents] = (params[:product].delete(:prix_euros).to_f * 100).round
      end

      if @product.update(product_params)
        redirect_to admin_products_path, notice: "\"#{@product.nom}\" mis à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/products/:id — bloqué si des commandes existent
    def destroy
      if @product.destroy
        redirect_to admin_products_path, notice: "\"#{@product.nom}\" supprimé."
      else
        redirect_to admin_products_path,
                    alert: "Impossible de supprimer \"#{@product.nom}\" : des commandes existent. Désactivez-le à la place."
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    # Liste des prestations utilisables pour le `prestation_id` d'un pack.
    # On ne propose que les poses complètes (categorie 'extensions').
    def set_poses_disponibles
      @poses_disponibles = Prestation.where(categorie: 'extensions').par_nom
    end

    def product_params
      params.require(:product).permit(
        :nom, :description, :type_produit,
        :prix_cents, :actif, :photo,
        # Spécifiques aux packs — nil pour les autres types (la BDD accepte NULL)
        :prestation_id, :nb_remplissages
      )
    end
  end
end
