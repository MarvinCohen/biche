module EspaceCliente
  # ============================================================
  # Profil cliente — informations personnelles et préférences notifications
  # ============================================================
  class ProfilController < BaseController
    # GET /espace-cliente/profil — affiche les infos du compte
    def show
      @user = current_user
    end

    # GET /espace-cliente/profil/edit — formulaire de modification
    def edit
      @user = current_user
    end

    # PATCH /espace-cliente/profil — sauvegarde les modifications
    def update
      @user = current_user

      if @user.update(profil_params)
        redirect_to espace_cliente_profil_path, notice: "Profil mis à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # Paramètres autorisés pour la mise à jour du profil
    # On n'autorise PAS email ni password ici (géré par Devise séparément)
    def profil_params
      params.require(:user).permit(:first_name, :last_name, :phone, :birth_date)
    end
  end
end
