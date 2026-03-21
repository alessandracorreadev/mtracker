class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = @chat.messages.new(message_params)
    @message.role = 'user'

    if @message.save
      # Enqueue the AI response job in the background (Solid Queue via PostgreSQL)
      # The controller returns immediately — the job streams the response via Turbo Streams
      CreateAiResponseJob.perform_later(@message)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to chat_path(@chat) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("chat_form_container",
            partial: "messages/form",
            locals: { chat: @chat, message: @message }
          )
        end
        format.html { redirect_to chat_path(@chat), alert: "Falha ao enviar mensagem." }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
