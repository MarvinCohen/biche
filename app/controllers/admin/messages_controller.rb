module Admin
  # ============================================================
  # Messages — Syam envoie des notifications / newsletters à ses clientes
  # ============================================================
  class MessagesController < BaseController

    # GET /admin/messages/new — formulaire d'envoi de message
    def new
      @message = Message.new

      # Liste des clientes pour la sélection de la destinataire
      # (ou option "toutes les clientes")
      @clientes = User.where(admin: false).order(:last_name, :first_name)
    end

    # POST /admin/messages — crée et envoie le message
    def create
      # Si user_id = "all", on crée un message pour chaque cliente
      if params[:message][:user_id] == 'all'
        User.where(admin: false).each do |cliente|
          Message.create!(
            user:         cliente,
            titre:        message_params[:titre],
            contenu:      message_params[:contenu],
            type_message: message_params[:type_message],
            lu:           false  # Nouveau message non lu par défaut
          )
        end
        redirect_to admin_root_path, notice: "Message envoyé à toutes les clientes."
      else
        # Envoi à une seule cliente
        @message = Message.new(message_params)
        @message.lu = false  # Non lu par défaut

        if @message.save
          redirect_to admin_root_path, notice: "Message envoyé."
        else
          @clientes = User.where(admin: false).order(:last_name, :first_name)
          render :new, status: :unprocessable_entity
        end
      end
    end

    private

    # Champs autorisés pour la création d'un message
    def message_params
      params.require(:message).permit(:user_id, :titre, :contenu, :type_message)
    end
  end
end
