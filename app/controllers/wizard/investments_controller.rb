module Wizard
  class InvestmentsController < ApplicationController
    before_action :authenticate_user!

    def new
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:message_id])
      @investment = Investment.new
      
      render partial: 'form', locals: { chat: @chat, message: @message, investment: @investment }
    end

    def create
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:message_id])
      @investment = current_user.investments.new(investment_params)

      if @investment.save
        @message.update!(content: "✅ Investimento registrado:\n**#{@investment.description}** — R$#{'%.2f' % @investment.value}\nTipo: #{@investment.investment_type}")
        
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "message_#{@message.id}",
              partial: "messages/message",
              locals: { message: @message }
            )
          end
        end
      else
        render partial: 'form', locals: { chat: @chat, message: @message, investment: @investment }, status: :unprocessable_entity
      end
    end

    def destroy
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:id])
      
      @message.update!(content: "❌ Registro de investimento cancelado.")
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_#{@message.id}",
            partial: "messages/message",
            locals: { message: @message }
          )
        end
      end
    end

    private

    def investment_params
      params.require(:investment).permit(:value, :date, :description, :investment_type, :interest_rate)
    end
  end
end
