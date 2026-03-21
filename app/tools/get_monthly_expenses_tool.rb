class GetMonthlyExpensesTool < RubyLLM::Tool
  description "Retorna a lista detalhada de todas as despesas de um mês e ano específicos do usuário. Use esta ferramenta quando o usuário perguntar sobre gastos, despesas ou compras de um período específico."

  params do
    integer :month, description: "Mês como número de 1 a 12 (ex: 2 para Fevereiro)"
    integer :year,  description: "Ano com 4 dígitos (ex: 2025)"
  end

  def initialize(user)
    @user = user
  end

  def execute(month:, year:)
    start_date = Date.new(year.to_i, month.to_i, 1)
    end_date   = start_date.end_of_month

    expenses = @user.expenses.where(date: start_date..end_date).order(:date)
    return "Nenhuma despesa encontrada em #{month}/#{year}." if expenses.none?

    total = expenses.sum(:value)
    by_category = expenses.group_by(&:expense_type)
                          .transform_values { |v| v.sum(&:value) }
                          .sort_by { |_, v| -v }

    items = expenses.map do |e|
      "  #{e.date.strftime('%d/%m')}: #{e.description} — R$#{"%.2f" % e.value} [#{e.expense_type}]"
    end

    category_summary = by_category.map { |cat, val| "#{cat}: R$#{"%.2f" % val}" }.join(", ")

    "Despesas em #{start_date.strftime('%B %Y')} — Total: R$#{"%.2f" % total}\n" \
    "Por categoria: #{category_summary}\n\n" \
    "Detalhes:\n#{items.join("\n")}"
  rescue => e
    "Erro ao buscar despesas: #{e.message}"
  end
end
