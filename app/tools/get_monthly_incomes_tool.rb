class GetMonthlyIncomesTool < RubyLLM::Tool
  description "Retorna a lista detalhada de todos os salários e rendimentos recebidos em um mês e ano específicos. Use esta ferramenta quando o usuário perguntar sobre receitas, salários ou entradas de dinheiro de um período."

  params do
    integer :month, description: "Mês como número de 1 a 12 (ex: 3 para Março)"
    integer :year,  description: "Ano com 4 dígitos (ex: 2025)"
  end

  def initialize(user)
    @user = user
  end

  def execute(month:, year:)
    start_date = Date.new(year.to_i, month.to_i, 1)
    end_date   = start_date.end_of_month

    incomes = @user.incomes.where(date: start_date..end_date).order(:date)
    return "Nenhuma receita encontrada em #{month}/#{year}." if incomes.none?

    total = incomes.sum(:value)
    items = incomes.map do |i|
      "  #{i.date.strftime('%d/%m')}: #{i.description} — R$#{"%.2f" % i.value} [#{i.income_type}]"
    end

    "Receitas em #{start_date.strftime('%B %Y')} — Total: R$#{"%.2f" % total}\n\n" \
    "Detalhes:\n#{items.join("\n")}"
  rescue => e
    "Erro ao buscar receitas: #{e.message}"
  end
end
