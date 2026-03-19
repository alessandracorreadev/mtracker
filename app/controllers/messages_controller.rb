class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = @chat.messages.new(message_params)
    @message.role = 'user'

    if @message.save
      call_llm(@chat)
      redirect_to chat_path(@chat)
    else
      redirect_to chat_path(@chat), alert: "Failed to send message."
    end
  end

  private

  def call_llm(chat)
    llm_chat = RubyLLM.chat(model: 'gpt-4o')
    user = current_user
    
    # Financial Context
    total_incomes = user.incomes.sum(:value) || 0
    total_expenses = user.expenses.sum(:value) || 0
    total_investments = user.investments.sum(:value) || 0
    balance = total_incomes - total_expenses
    
    recent_transactions = []
    recent_transactions += user.incomes.order(date: :desc).limit(3).map { |i| "Income: #{i.description} ($#{i.value}) on #{i.date}" }
    recent_transactions += user.expenses.order(date: :desc).limit(3).map { |e| "Expense: #{e.description} ($#{e.value}) on #{e.date}" }
    
    context = <<~CONTEXT
      User Context:
      - Total Incomes: $#{total_incomes}
      - Total Expenses: $#{total_expenses}
      - Current Balance: $#{balance}
      - Total Investments: $#{total_investments}
      
      Recent Transactions (up to 3 each):
      #{recent_transactions.any? ? recent_transactions.join("\n") : "No recent transactions found."}
    CONTEXT
    
    # We build a simple text history for context
    history = chat.messages.order(:created_at).last(10).map do |msg|
      "#{msg.role == 'user' ? 'User' : 'Assistant'}: #{msg.content}"
    end.join("\n")

    prompt = "You are a helpful financial assistant for the mtracker app. Help the user manage tracking income, expenses, and investments based on their current financial profile.\n" \
             "IMPORTANT: Do NOT use any Markdown formatting (like **, _, or #) in your responses. Always use plain text, but use line breaks and paragraphs to separate information.\n\n" \
             "#{context}\n\n" \
             "Here is the recent conversation:\n#{history}\n\nAssistant:"

    response = llm_chat.ask(prompt)
    chat.messages.create!(role: 'assistant', content: response.content)
  rescue StandardError => e
    chat.messages.create!(role: 'assistant', content: "Sorry, I encountered an error: #{e.message}")
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
