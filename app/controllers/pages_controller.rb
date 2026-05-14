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

    # URL de la dernière vidéo TikTok à afficher (gérée par Syam depuis l'admin).
    # Nil ou vide → la section TikTok ne s'affiche pas (logique dans le partial).
    @tiktok_url = SiteSetting.get("tiktok_latest_url")
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

    # Vidéos Instagram actives triées par position, avec miniature préchargée
    @videos = Video.actives.avec_miniature

    # URL de la dernière vidéo TikTok (idem que sur la home — gérée par Syam).
    @tiktok_url = SiteSetting.get("tiktok_latest_url")
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
    @produits_routine = Product.actifs.where(type_produit: 'routine').with_attached_photo
    @produits_carte   = Product.actifs.where(type_produit: 'carte_cadeau').first

    # Packs de remplissage : groupés par pose pour permettre le filtrage en pills
    # côté vue. On précharge :prestation (pour le nom de la pose) + photo.
    # `par_pose` trie par nom de pose puis par nb_remplissages croissant
    # → l'ordre 3/6/9 est garanti dans chaque groupe.
    # On exclut les packs orphelins (prestation supprimée ou prestation_id nil)
    # pour éviter de générer une clé `nil` dans @packs_par_pose, qui ferait planter
    # la vue au moment d'appeler `.id` / `.nom` sur la pose dans les pills.
    @produits_packs = Product.actifs.packs.par_pose.includes(:prestation).with_attached_photo
                              .where.not(prestation_id: nil)
    # Groupe par prestation (objet) pour ne pas avoir à le re-chercher dans la vue.
    # Hash : { Prestation => [Pack3, Pack6, Pack9], ... }
    # Double sécurité : on filtre encore les clés nil au cas où la prestation
    # référencée existerait en base mais aurait été soft-deleted ailleurs.
    @packs_par_pose = @produits_packs.group_by(&:prestation).reject { |pose, _| pose.nil? }
  end
end
