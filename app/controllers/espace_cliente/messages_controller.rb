module EspaceCliente
  # ============================================================
  # Messages — newsletters, rappels RDV, offres, anniversaire
  # ============================================================
  class MessagesController < BaseController
    before_action :set_message, only: [:show, :marquer_lu]

    # GET /espace-cliente/messages — tous les messages, du plus récent au plus ancien
    def index
      @messages = current_user.messages.recents
    end

    # GET /espace-cliente/messages/:id — affiche un message et le marque comme lu
    def show
      # Marque automatiquement le message comme lu à l'ouverture
      @message.marquer_comme_lu! unless @message.lu
    end

    # PATCH /espace-cliente/messages/:id/marquer_lu — marque un message comme lu (depuis la liste)
    def marquer_lu
      @message.marquer_comme_lu!
      redirect_to espace_cliente_messages_path
    end

    private

    # Trouve le message en vérifiant qu'il appartient à la cliente connectée
    def set_message
      @message = current_user.messages.find(params[:id])
    end
  end
end
