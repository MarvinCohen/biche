module Admin
  # ============================================================
  # Vidéos Instagram — Syam gère ses reels depuis l'admin
  # ============================================================
  class VideosController < BaseController

    before_action :set_video, only: [:edit, :update, :destroy]

    # GET /admin/videos — liste de toutes les vidéos
    def index
      # Triées par position, avec miniature préchargée (évite N+1)
      @videos = Video.ordonnes.avec_miniature
    end

    # GET /admin/videos/new — formulaire d'ajout
    def new
      @video = Video.new
      # Position par défaut : après la dernière vidéo existante
      @video.position = (Video.maximum(:position) || 0) + 1
    end

    # POST /admin/videos — sauvegarde la nouvelle vidéo
    def create
      @video = Video.new(video_params)

      if @video.save
        redirect_to admin_videos_path, notice: "Vidéo ajoutée."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/videos/:id/edit — formulaire de modification
    def edit
    end

    # PATCH /admin/videos/:id — sauvegarde les modifications
    def update
      if @video.update(video_params)
        redirect_to admin_videos_path, notice: "Vidéo mise à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/videos/:id — supprime la vidéo et sa miniature
    def destroy
      # Purge la miniature Active Storage avant de supprimer l'enregistrement
      @video.miniature.purge if @video.miniature.attached?
      @video.destroy
      redirect_to admin_videos_path, notice: "Vidéo supprimée."
    end

    # PATCH /admin/videos/reordonner — reçoit le nouvel ordre en AJAX
    # Appelé après un drag-and-drop dans la liste admin
    def reordonner
      # params[:ordre] = ["3", "1", "5", "2"] — IDs dans le nouvel ordre
      params[:ordre].each_with_index do |id, index|
        Video.where(id: id).update_all(position: index + 1)
      end
      head :ok  # Réponse vide 200 — le JS n'a pas besoin d'un body
    end

    private

    # Charge la vidéo depuis l'URL
    def set_video
      @video = Video.find(params[:id])
    end

    # Champs autorisés pour créer ou modifier une vidéo
    def video_params
      params.require(:video).permit(:titre, :url, :tag, :position, :actif, :miniature, :video_file)
    end
  end
end
