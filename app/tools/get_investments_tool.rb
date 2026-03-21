class GetInvestmentsTool < RubyLLM::Tool
  description "Retorna a lista de investimentos do usuário com seus rendimentos acumulados. Pode filtrar por tipo (CDB, Tesouro SELIC, Ações, FII, etc.) ou trazer todos os investimentos. Use quando o usuário perguntar sobre investimentos, carteira, rendimentos ou patrimônio."

  params do
    string :investment_type, description: "Tipo do investimento para filtrar (ex: CDB, Tesouro SELIC, Ações, FII). Envie 'todos' ou deixe vazio para listar todos."
  end

  def initialize(user)
    @user = user
  end

  def execute(investment_type: "todos")
    investments = @user.investments.order(:date)
    investments = investments.where(investment_type: investment_type) unless investment_type.blank? || investment_type.downcase == "todos"

    return "Nenhum investimento encontrado#{investment_type && investment_type.downcase != "todos" ? " do tipo #{investment_type}" : ""}." if investments.none?

    total_invested = investments.sum(:value)
    total_current  = investments.sum(&:current_value)
    total_yield    = total_current - total_invested

    items = investments.map do |inv|
      yield_pct = inv.value > 0 ? ((inv.accumulated_yield / inv.value) * 100).round(1) : 0
      "  #{inv.date.strftime('%m/%Y')}: #{inv.description} [#{inv.investment_type}] — " \
      "Aportado: R$#{"%.2f" % inv.value} | Atual: R$#{"%.2f" % inv.current_value} | " \
      "Rendimento: +R$#{"%.2f" % inv.accumulated_yield} (#{yield_pct}%)" \
      "#{inv.interest_rate.present? ? " @ #{inv.interest_rate}% a.a." : ""}"
    end

    "Investimentos#{investment_type && investment_type.downcase != "todos" ? " — #{investment_type}" : " (todos)"}:\n" \
    "  Total Aportado: R$#{"%.2f" % total_invested}\n" \
    "  Valor Atual: R$#{"%.2f" % total_current}\n" \
    "  Rendimento Total: +R$#{"%.2f" % total_yield}\n\n" \
    "Detalhes:\n#{items.join("\n")}"
  rescue => e
    "Erro ao buscar investimentos: #{e.message}"
  end
end
