class GetMonthlySummaryTool < RubyLLM::Tool
  description "Retorna um resumo financeiro completo de um mês específico: total de receitas, despesas, saldo do mês e maiores gastos por categoria. Use quando o usuário quiser um panorama geral de um período."

  params do
    integer :month, description: "Mês como número de 1 a 12"
    integer :year,  description: "Ano com 4 dígitos (ex: 2025)"
  end

  def initialize(user)
    @user = user
  end

  def execute(month:, year:)
    start_date = Date.new(year.to_i, month.to_i, 1)
    end_date   = start_date.end_of_month

    total_incomes  = @user.incomes.where(date: start_date..end_date).sum(:value)
    total_expenses = @user.expenses.where(date: start_date..end_date).sum(:value)
    balance        = total_incomes - total_expenses

    top_categories = @user.expenses
                          .where(date: start_date..end_date)
                          .group(:expense_type)
                          .sum(:value)
                          .sort_by { |_, v| -v }
                          .first(3)
                          .map { |cat, val| "#{cat}: R$#{"%.2f" % val}" }

    expense_count = @user.expenses.where(date: start_date..end_date).count
    income_count  = @user.incomes.where(date: start_date..end_date).count

    "Resumo de #{start_date.strftime('%B %Y')}:\n" \
    "  Receitas: R$#{"%.2f" % total_incomes} (#{income_count} lançamentos)\n" \
    "  Despesas: R$#{"%.2f" % total_expenses} (#{expense_count} lançamentos)\n" \
    "  Saldo do mês: R$#{"%.2f" % balance}#{balance >= 0 ? " (positivo)" : " (negativo)"}\n" \
    "  Maiores categorias de gasto: #{top_categories.any? ? top_categories.join(", ") : "nenhuma"}"
  rescue => e
    "Erro ao calcular resumo: #{e.message}"
  end
end
