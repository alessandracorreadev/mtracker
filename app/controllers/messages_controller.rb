class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = @chat.messages.new(message_params)
    @message.role = 'user'

    if @message.save
      # Create assistant message placeholder
      @assistant_message = @chat.messages.create!(role: 'assistant', content: '')
      
      # Call LLM and stream chunks
      call_llm(@chat, @assistant_message)

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

  def call_llm(chat, assistant_msg)
    user = current_user

    system_instructions = build_system_instructions(user)
    llm_chat = RubyLLM.chat.with_instructions(system_instructions)

    # Replay all context
    chat.messages.order(:created_at).each do |msg|
      next if msg == assistant_msg || msg.content.blank?
      llm_chat.add_message(role: msg.role, content: msg.content)
    end

    full_response = ""
    
    # Broadcast placeholder before starting
    broadcast_replace(chat, assistant_msg)

    # Ask and stream
    llm_chat.ask(chat.messages.where(role: 'user').last.content) do |chunk|
      delta = chunk.content.to_s
      next if delta.empty?

      full_response << delta
      assistant_msg.content = full_response
      
      # Broadcast the accumulated response
      broadcast_replace(chat, assistant_msg)
    end

    # Detect and save transaction if present
    clean_content = parse_and_save_transaction(full_response, user)
    
    # Update final assistant message in DB
    assistant_msg.update!(content: clean_content)
    
    # Final broadcast (without JSON marker)
    broadcast_replace(chat, assistant_msg)
  rescue StandardError => e
    assistant_msg.update!(content: "Erro: #{e.message}")
    broadcast_replace(chat, assistant_msg)
  end

  def build_system_instructions(user)
    total_incomes     = user.incomes.sum(:value) || 0
    total_expenses    = user.expenses.sum(:value) || 0
    total_investments = user.investments.sum(:value) || 0
    balance = total_incomes - total_expenses
    
    # Monthly summaries for the last few months
    monthly_expenses = user.expenses.where(date: 6.months.ago..Date.today)
                           .group_by { |e| e.date.strftime("%B %Y") }
                           .transform_values { |v| v.sum(&:value) }
    
    monthly_incomes = user.incomes.where(date: 6.months.ago..Date.today)
                          .group_by { |i| i.date.strftime("%B %Y") }
                          .transform_values { |v| v.sum(&:value) }

    # More recent transactions (last 15)
    recent_transactions = []
    recent_transactions += user.incomes.order(date: :desc).limit(10).map  { |i| "Income: #{i.description} (R$#{i.value}) on #{i.date}" }
    recent_transactions += user.expenses.order(date: :desc).limit(15).map { |e| "Expense: #{e.description} (R$#{e.value}) on #{e.date}" }

    <<~INSTRUCTIONS
      You are a minimalist financial assistant for the mtracker app.
      
      CRITICAL STYLE RULES:
      1. PLAIN TEXT ONLY: Never use Markdown (no **, no #, no `-`, no ```).
      2. BE CONCISE BUT COMPLETE: Always prioritize being direct and brief, but ensure you complete your thought and provide a helpful answer.
      3. LANGUAGE: Always respond in Portuguese (PT-BR).

      Financial Context:
      - Total Incomes: R$#{total_incomes}
      - Total Expenses: R$#{total_expenses}
      - Current Balance: R$#{balance}
      - Total Investments: R$#{total_investments}

      Monthly Summaries (Last 6 Months):
      - Expenses: #{monthly_expenses.map { |k, v| "#{k}: R$#{v}" }.join(", ")}
      - Incomes: #{monthly_incomes.map { |k, v| "#{k}: R$#{v}" }.join(", ")}

      Recent Transactions:
      #{recent_transactions.any? ? recent_transactions.join("\n") : "No recent transactions found."}

      --- TRANSACTION DETECTION ---
      If the user describes a financial transaction, append a JSON block at the very end:
      [TRANSACTION:{"type":"expense","description":"Mercado","value":50.0,"date":"#{Date.today}","category":"Alimentação"}]
    INSTRUCTIONS
  end

  def parse_and_save_transaction(content, user)
    match = content.match(/\[TRANSACTION:(.*?)\]/m)
    return content unless match

    begin
      json_str = match[1].strip
      data = JSON.parse(json_str)
      case data['type']
      when 'expense' then user.expenses.create!(description: data['description'], value: data['value'].to_f, date: Date.parse(data['date']), expense_type: data['category'])
      when 'income'  then user.incomes.create!(description: data['description'], value: data['value'].to_f, date: Date.parse(data['date']), income_type: data['income_type'] || data['category'])
      when 'investment' then user.investments.create!(description: data['description'], value: data['value'].to_f, date: Date.parse(data['date']), investment_type: data['investment_type'] || data['category'])
      end
    rescue => e
      Rails.logger.error "Transaction Error: #{e.message}"
    end
    content.gsub(/\[TRANSACTION:.*?\]/m, '').strip
  end

  def broadcast_replace(chat, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      chat,
      target: "message_#{message.id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
