class ShopController < ApplicationController
  # ============================================================
  # Boutique — cartes cadeaux, packs multi-visites, produits routine
  # ============================================================

  # GET /shop — page principale de la boutique
  def index
    # On charge les 3 types de produits séparément (3 sections dans la maquette)
    @cartes_cadeaux = Product.actifs.cartes_cadeaux
    @packs          = Product.actifs.packs
    @produits       = Product.actifs.routine
  end
end
