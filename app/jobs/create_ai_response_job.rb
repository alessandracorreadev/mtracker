class CreateAiResponseJob < ApplicationJob
  queue_as :default

  include ActionView::RecordIdentifier

  # Max characters to send as conversation history (~3000 tokens)
  MAX_CONTEXT_CHARS = 12_000

  def perform(user_message)
    @message    = user_message
    @chat       = user_message.chat
    @user       = @chat.user
    @assistant_message = @chat.messages.create!(role: 'assistant', content: '')

    # Cache system prompt per user — invalidated on transaction creation/update
    system_instructions = Rails.cache.fetch("ai_context_#{@user.id}", expires_in: 5.minutes) do
      build_system_instructions(@user)
    end

    llm_chat = RubyLLM.chat.with_instructions(system_instructions)

    # Register tools so the AI can fetch detailed financial data on demand
    llm_chat.with_tools(
      GetMonthlyExpensesTool.new(@user),
      GetMonthlyIncomesTool.new(@user),
      GetMonthlySummaryTool.new(@user),
      GetInvestmentsTool.new(@user),
      ShowTransactionSelectorTool.new
    )

    # Build context window by character budget, not message count
    context_messages = build_context_by_volume(@chat, @assistant_message.id)
    context_messages.each do |msg|
      llm_chat.add_message(role: msg.role, content: msg.content)
    end

    full_response = ""

    # Broadcast the empty placeholder first (typing indicator)
    broadcast_replace(@assistant_message)

    # Ask and stream chunks
    llm_chat.ask(@message.content) do |chunk|
      delta = chunk.content.to_s
      next if delta.empty?

      full_response << delta
      @assistant_message.content = full_response
      broadcast_replace(@assistant_message)
    end

    # Detect and save a transaction if the AI detected one
    clean_content = parse_and_save_transaction(full_response, @user)

    if clean_content.blank? && @transaction_saved
      clean_content = "Transação registrada com sucesso!"
    end

    # Persist final clean response
    @assistant_message.update!(content: clean_content)
    broadcast_replace(@assistant_message)

  rescue StandardError => e
    error_msg = case e.message
                when /rate limit/i   then "Muitas mensagens em pouco tempo. Aguarde 1 minuto e tente novamente."
                when /timeout/i      then "A IA demorou muito para responder. Tente novamente."
                when /unauthorized/i then "Problema de autenticação com a IA. Contate o suporte."
                else "Algo deu errado ao processar sua mensagem. Tente novamente."
                end
    @assistant_message&.update!(content: error_msg)
    broadcast_replace(@assistant_message) if @assistant_message
  end

  private

  # Builds a context window of recent messages limited by total character count.
  # This is safer than limiting by message count because one long message can
  # consume as many tokens as many shorter ones.
  def build_context_by_volume(chat, exclude_id)
    budget = 0
    chat.messages
      .where.not(id: exclude_id)
      .where.not(content: [nil, ''])
      .order(created_at: :desc)
      .each_with_object([]) do |msg, ctx|
        msg_length = msg.content.to_s.length
        break if budget + msg_length > MAX_CONTEXT_CHARS
        budget += msg_length
        ctx.unshift(msg) # prepend to keep chronological order
      end
  end

  def broadcast_replace(message)
    Turbo::StreamsChannel.broadcast_replace_to(
      @chat,
      target: "message_#{message.id}",
      partial: "messages/message",
      locals: { message: message }
    )
  end

  def build_system_instructions(user)
    total_incomes     = user.incomes.sum(:value) || 0
    total_expenses    = user.expenses.sum(:value) || 0
    total_investments_cost = user.investments.sum(:value) || 0
    total_investments_current = user.investments.map(&:current_value).sum
    
    # Liquid balance = what's left in the pocket
    liquid_balance = total_incomes - total_expenses - total_investments_cost
    
    # Total yield since beginning
    total_yield = total_investments_current - total_investments_cost

    monthly_expenses = user.expenses.where(date: 6.months.ago..Date.today)
                           .group_by { |e| e.date.strftime("%B %Y") }
                           .transform_values { |v| v.sum(&:value) }

    monthly_incomes = user.incomes.where(date: 6.months.ago..Date.today)
                          .group_by { |i| i.date.strftime("%B %Y") }
                          .transform_values { |v| v.sum(&:value) }

    recent_transactions = []
    recent_transactions += user.incomes.order(date: :desc).limit(10).map  { |i| "Income: #{i.description} (R$#{i.value}) on #{i.date}" }
    recent_transactions += user.expenses.order(date: :desc).limit(15).map { |e| "Expense: #{e.description} (R$#{e.value}) on #{e.date}" }

    <<~INSTRUCTIONS
      You are a minimalist financial assistant for the mtracker app.

      CRITICAL STYLE RULES:
      1. PLAIN TEXT ONLY: Never use Markdown (no **, no #, no `-`, no ```).
      2. BE CONCISE BUT COMPLETE: Always prioritize being direct and brief.
      3. LANGUAGE: Always respond in Portuguese (PT-BR).

      Financial Context (Consolidated):
      - Total Incomes: R$#{total_incomes}
      - Total Expenses: R$#{total_expenses}
      - Total Investments (Cost): R$#{total_investments_cost}
      - Portfolio Current Value: R$#{total_investments_current}
      - Portfolio Total Yield: R$#{total_yield}
      - Liquid Balance (Available): R$#{liquid_balance}

      Monthly Summaries (Last 6 Months):
      - Expenses: #{monthly_expenses.map { |k, v| "#{k}: R$#{v}" }.join(", ")}
      - Incomes: #{monthly_incomes.map { |k, v| "#{k}: R$#{v}" }.join(", ")}

      Recent Transactions:
      #{recent_transactions.any? ? recent_transactions.join("\n") : "No recent transactions found."}

      --- TRANSACTION DETECTION ---
      If the user describes a financial transaction, append a JSON block at the very end:
      [TRANSACTION:{"type":"expense","description":"Mercado","value":50.0,"date":"#{Date.today}","category":"Alimentação"}]
      [TRANSACTION:{"type":"investment","description":"Tesouro SELIC","value":1000.0,"date":"#{Date.today}","category":"Renda Fixa","interest_rate":0.12}]
      (NOTE: for investments, always include the interest_rate if mentioned, e.g. 0.12 for 12% per year)
    INSTRUCTIONS
  end

  def parse_and_save_transaction(content, user)
    match = content.match(/\[TRANSACTION:(.*?)\]/m)
    return content unless match

    begin
      json_str = match[1].strip
      data = JSON.parse(json_str)
      case data['type']
      when 'expense'    then user.expenses.create!(description: data['description'], value: data['value'].to_f, date: Date.parse(data['date']), expense_type: data['category'])
      when 'income'     then user.incomes.create!(description: data['description'], value: data['value'].to_f, date: Date.parse(data['date']), income_type: data['income_type'] || data['category'])
      when 'investment' then user.investments.create!(description: data['description'], value: data['value'].to_f, date: Date.parse(data['date']), investment_type: data['investment_type'] || data['category'], interest_rate: data['interest_rate'])
      end
      @transaction_saved = true
    rescue => e
      Rails.logger.error "AI Transaction Parse Error: #{e.message}"
    end
    content.gsub(/\[TRANSACTION:.*?\]/m, '').strip
  end
end
