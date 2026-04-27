class PagesController < ApplicationController
  # ============================================================
  # Pages informatives — accessibles sans authentification
  # ============================================================

  # GET / — Page d'accueil avec carrousel prestations + best-sellers shop
  def home
    # On charge les 4 premières prestations dispo pour le carrousel
    @prestations = Prestation.disponibles.par_nom.limit(4)
    # Un produit actif par catégorie pour les best-sellers de la home
    # On prend le premier de chaque type : carte_cadeau, pack, routine
    @produits = Product::TYPES.filter_map { |type| Product.actifs.where(type_produit: type).first }
  end

  # GET /a-propos
  def about
  end

  # GET /faq
  def faq
  end

  # GET /galerie
  def galerie
  end

  # GET /morphologie
  def morphologie
  end

  # GET /avis
  def avis
  end

  # GET /contact
  def contact
  end

  # GET /shop — Page boutique avec cartes cadeaux et packs
  def shop
  end
end
