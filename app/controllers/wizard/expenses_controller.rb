module Wizard
  class ExpensesController < ApplicationController
    before_action :authenticate_user!

    def new
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:message_id])
      @expense = Expense.new
      
      render partial: 'form', locals: { chat: @chat, message: @message, expense: @expense }
    end

    def create
      @chat = current_user.chats.find(params[:chat_id])
      @message = @chat.messages.find(params[:message_id])
      @expense = current_user.expenses.new(expense_params)

      if @expense.save
        @message.update!(content: "✅ Gasto registrado:\n**#{@expense.description}** — R$#{'%.2f' % @expense.value}\nCategoria: #{@expense.expense_type}")
        
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
        render partial: 'form', locals: { chat: @chat, message: @message, expense: @expense }, status: :unprocessable_entity
      end
    end

    private

    def expense_params
      params.require(:expense).permit(:value, :date, :description, :expense_type)
    end
  end
end
