class PagesController < ApplicationController
  # ============================================================
  # Pages informatives — accessibles sans authentification
  # ============================================================

  # GET / — Page d'accueil avec carrousel prestations + best-sellers shop
  def home
    # Prestations dispo pour le carrousel — avec photo préchargée (évite N+1)
    @prestations = Prestation.disponibles.par_nom.with_attached_photo.limit(4)

    # Un produit actif par catégorie pour les best-sellers de la home
    @produits = Product::TYPES.filter_map { |type| Product.actifs.where(type_produit: type).first }

    # Photos de galerie groupées par catégorie — utilisées en fallback si une
    # prestation n'a pas encore de photo propre. On prend la première photo
    # disponible par catégorie de galerie pour illustrer les cartes.
    galerie = GaleriePhoto.avec_image.select { |p| p.image.attached? }
    @galerie_par_categorie = galerie.group_by(&:categorie).transform_values(&:first)
  end

  # GET /a-propos
  def about
  end

  # GET /faq
  def faq
  end

  # GET /galerie — Page galerie avec grille masonry dynamique depuis la BDD
  def galerie
    # Charger toutes les photos triées par position, avec images préchargées (évite N+1)
    @galerie_photos = GaleriePhoto.ordonnes.avec_image

    # Les 4 premières photos ayant une image attachée — utilisées pour le collage hero
    # On filtre avec select pour ne garder que celles qui ont vraiment un fichier
    @collage_photos = @galerie_photos.select { |p| p.image.attached? }.first(4)
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

  # GET /shop — Page boutique avec cartes cadeaux, packs et produits routine
  def shop
    # Produits actifs par type, avec photo préchargée (évite N+1)
    @produits_routine     = Product.actifs.where(type_produit: 'routine').with_attached_photo
    @produits_packs       = Product.actifs.where(type_produit: 'pack').with_attached_photo
    @produits_carte       = Product.actifs.where(type_produit: 'carte_cadeau').first
  end
end
