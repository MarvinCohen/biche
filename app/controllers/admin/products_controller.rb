module Admin
  # ============================================================
  # Produits boutique — CRUD complet
  # Syam peut gérer cartes cadeaux, packs et produits routine.
  # ============================================================
  class ProductsController < BaseController

    before_action :set_product, only: [:edit, :update, :destroy]

    # GET /admin/products — liste groupée par type
    def index
      # Tous les produits (actifs et inactifs) groupés par type, avec photo préchargée
      @products_par_type = Product
                             .order(:type_produit, :nom)
                             .with_attached_photo
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

    def product_params
      params.require(:product).permit(
        :nom, :description, :type_produit,
        :prix_cents, :actif, :photo
      )
    end
  end
end
