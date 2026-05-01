class Admin::GaleriePhotosController < Admin::BaseController
  # ============================================================
  # Gestion des photos de la galerie — CRUD depuis l'interface admin
  # Syam peut ajouter, supprimer et réordonner les photos de la galerie.
  # ============================================================

  # Factoriser la recherche du record pour les actions qui ciblent une photo précise
  before_action :set_galerie_photo, only: [:destroy]

  # GET /admin/galerie_photos
  # Liste toutes les photos de la galerie, triées par position, avec images préchargées
  def index
    @galerie_photos = GaleriePhoto.ordonnes.avec_image
  end

  # GET /admin/galerie_photos/new
  # Formulaire pour ajouter une nouvelle photo à la galerie
  def new
    @galerie_photo = GaleriePhoto.new
    # Pré-remplir la position avec la prochaine valeur disponible
    @galerie_photo.position = GaleriePhoto.count + 1
  end

  # POST /admin/galerie_photos
  # Créer une nouvelle entrée dans la galerie avec son image uploadée
  def create
    @galerie_photo = GaleriePhoto.new(galerie_photo_params)

    if @galerie_photo.save
      redirect_to admin_galerie_photos_path, notice: "Photo ajoutée à la galerie."
    else
      # Erreur de validation → réafficher le formulaire avec les messages d'erreur
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /admin/galerie_photos/:id
  # Supprimer une photo (et son fichier attaché via Active Storage)
  def destroy
    # Active Storage supprime automatiquement le fichier associé
    @galerie_photo.destroy
    redirect_to admin_galerie_photos_path, notice: "Photo supprimée."
  end

  # PATCH /admin/galerie_photos/reordonner
  # Réception d'un tableau d'IDs dans l'ordre désiré — mise à jour des positions
  # Appelé en AJAX depuis l'interface de drag-and-drop admin
  def reordonner
    # params[:ordre] contient un tableau d'IDs dans le nouvel ordre, ex: ["3", "1", "5"]
    params[:ordre].each_with_index do |id, index|
      # Mise à jour directe sans callbacks pour la performance (simple mise à jour de position)
      GaleriePhoto.where(id: id).update_all(position: index + 1)
    end

    # Répondre avec un JSON vide pour confirmer le succès à la requête AJAX
    head :ok
  end

  private

  # Retrouver la photo par son ID — utilisé par before_action
  def set_galerie_photo
    @galerie_photo = GaleriePhoto.find(params[:id])
  end

  # Paramètres autorisés pour la création d'une photo
  def galerie_photo_params
    params.require(:galerie_photo).permit(
      :legende,     # Texte principal sur la photo
      :legende_sub, # Sous-titre (ex: "Pose complète · 2h" pour avant/après)
      :categorie,   # Catégorie pour le filtre JS
      :taille,      # Hauteur dans la grille masonry : tall / medium / short
      :position,    # Ordre d'affichage
      :image,       # Photo principale (ou photo "avant" pour avant/après)
      :image_apres  # Photo "après" — uniquement pour la catégorie avant-apres
    )
  end
end
