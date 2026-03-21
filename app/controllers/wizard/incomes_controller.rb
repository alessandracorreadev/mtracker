module Wizard
  class IncomesController < ApplicationController
    before_action :authenticate_user!

    def new
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:message_id])
      @income = Income.new
      
      render partial: 'form', locals: { chat: @chat, message: @message, income: @income }
    end

    def create
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:message_id])
      @income = current_user.incomes.new(income_params)

      if @income.save
        @message.update!(content: "✅ Receita registrada:\n**#{@income.description}** — R$#{'%.2f' % @income.value}\nCategoria: #{@income.income_type}")
        
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
        render partial: 'form', locals: { chat: @chat, message: @message, income: @income }, status: :unprocessable_entity
      end
    end

    def destroy
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:id])
      
      @message.update!(content: "❌ Registro de receita cancelado.")
      
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

    def income_params
      params.require(:income).permit(:value, :date, :description, :income_type)
    end
  end
end
