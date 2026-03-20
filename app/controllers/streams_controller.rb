class StreamsController < ApplicationController
  include ActionController::Live
  before_action :authenticate_user!

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no' # Disable nginx buffering if used

    @chat = current_user.chats.find(params[:chat_id])

    sse = ActionController::Live::SSE.new(response.stream, retry: 300, event: 'chunk')

    begin
      full_response = ""

      llm_chat = build_llm_chat(@chat)
      last_user_message = @chat.messages.where(role: 'user').last

      llm_chat.ask(last_user_message.content) do |chunk|
        delta = chunk.content.to_s
        next if delta.empty?

        full_response << delta

        # Stream accumulated content to the frontend
        sse.write({ content: full_response }, event: 'chunk')
      end

      # Transaction detection: parse JSON marker if present
      clean_content = parse_and_save_transaction(full_response, current_user)

      # Save the final assistant message (without the hidden JSON marker)
      @chat.messages.create!(role: 'assistant', content: clean_content)

      # If the content was cleaned (transaction saved), send the final clean version
      if clean_content != full_response
        sse.write({ content: clean_content }, event: 'chunk')
      end

      sse.write({}, event: 'done')

    rescue ActionController::Live::ClientDisconnected
      # Browser closed the connection - silent fail
    rescue StandardError => e
      sse.write({ error: "Erro: #{e.message}" }, event: 'error')
    ensure
      sse.close
    end
  end

  private

  def build_llm_chat(chat)
    user = current_user

    total_incomes     = user.incomes.sum(:value) || 0
    total_expenses    = user.expenses.sum(:value) || 0
    total_investments = user.investments.sum(:value) || 0
    balance = total_incomes - total_expenses

    recent_transactions = []
    recent_transactions += user.incomes.order(date: :desc).limit(3).map  { |i| "Income: #{i.description} (R$#{i.value}) on #{i.date}" }
    recent_transactions += user.expenses.order(date: :desc).limit(3).map { |e| "Expense: #{e.description} (R$#{e.value}) on #{e.date}" }

    system_instructions = <<~INSTRUCTIONS
      You are a helpful financial assistant for the mtracker app. Respond in the same language as the user.
      Help the user manage and track income, expenses, and investments.
      IMPORTANT: Do NOT use any Markdown formatting (like **, _, or #). Always use plain text with line breaks and paragraphs.

      User's Financial Profile:
      - Total Incomes: R$#{total_incomes}
      - Total Expenses: R$#{total_expenses}
      - Current Balance: R$#{balance}
      - Total Investments: R$#{total_investments}

      Recent Transactions:
      #{recent_transactions.any? ? recent_transactions.join("\n") : "No recent transactions found."}

      --- TRANSACTION DETECTION ---
      If the user describes a financial transaction, append a JSON block at the very end:
      [TRANSACTION:{"type":"expense","description":"Mercado","value":50.0,"date":"#{Date.today}","category":"Alimentação"}]
      Rules:
      - "type": "expense", "income", or "investment"
      - "value": positive number
      - "date": YYYY-MM-DD format (use today if not mentioned: #{Date.today})
      - "category" in Portuguese
      - For income, use "income_type" instead of "category"
      - For investment, use "investment_type" instead of "category"
      - Only include if confident a transaction was described. Do NOT explain the block.
    INSTRUCTIONS

    llm = RubyLLM.chat(model: 'gpt-4o').with_instructions(system_instructions)

    chat.messages.order(:created_at).each do |msg|
      llm.add_message(role: msg.role, content: msg.content)
    end

    llm
  end

  def parse_and_save_transaction(content, user)
    match = content.match(/\[TRANSACTION:(.*?)\]/m)
    return content unless match

    json_str = match[1].strip
    data = JSON.parse(json_str)

    case data['type']
    when 'expense'
      user.expenses.create!(
        description: data['description'],
        value: data['value'].to_f,
        date: Date.parse(data['date']),
        expense_type: data['category']
      )
    when 'income'
      user.incomes.create!(
        description: data['description'],
        value: data['value'].to_f,
        date: Date.parse(data['date']),
        income_type: data['income_type'] || data['category']
      )
    when 'investment'
      user.investments.create!(
        description: data['description'],
        value: data['value'].to_f,
        date: Date.parse(data['date']),
        investment_type: data['investment_type'] || data['category']
      )
    end

    content.gsub(/\[TRANSACTION:.*?\]/m, '').strip
  rescue JSON::ParserError, ArgumentError
    content
  end
end
