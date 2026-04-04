# Limpeza inicial para o usuário de teste
puts "Limpando dados antigos do usuário teste..."
user = User.find_or_initialize_by(email: "teste@mtracker.com")
if user.new_record?
  user.assign_attributes(password: "123456", password_confirmation: "123456", name: "Usuário Teste", birth_date: Date.new(1990, 5, 15))
  user.save!
end

user.expenses.destroy_all
user.incomes.destroy_all
user.investments.destroy_all
user.goals.destroy_all

puts "Gerando dados detalhados de Janeiro 2024 até Março 2026..."

start_date = Date.new(2024, 1, 1)
end_date = Date.new(2026, 3, 31)
current_month = start_date

# Dados base
salario_base = 6500.00
aluguel = 1800.00
condominio = 450.00
plano_saude = 350.00
internet = 120.00

while current_month <= end_date
  # Aumentos anuais
  if current_month.month == 1 && current_month.year > 2024
    salario_base *= 1.08
    aluguel *= 1.05
    condominio *= 1.05
  end

  # ==========================================
  # RENDAS (Incomes)
  # ==========================================

  # Salário mensal fixo
  user.incomes.create!(
    date: current_month.change(day: 5),
    value: salario_base.round(2),
    income_type: "Salário",
    description: "Salário Mensal - #{current_month.strftime('%B')}"
  )

  # Bônus ou 13º no final do ano
  if current_month.month == 12 || current_month.month == 6
    user.incomes.create!(
      date: current_month.change(day: 20),
      value: (salario_base * 0.5).round(2),
      income_type: "Comissão",
      description: current_month.month == 12 ? "13º Salário (2ª Parcela)" : "Recesso de Meio de Ano"
    )
  end

  # Freelance ocasional (30% de chance no mês)
  if rand < 0.3
    user.incomes.create!(
      date: current_month.change(day: rand(5..28)),
      value: rand(800.0..2500.0).round(2),
      income_type: "Freelance",
      description: ["Projeto Web", "Consultoria Técnica", "Desenvolvimento API", "Design de Tela"].sample
    )
  end

  # Pequenas entradas compatíveis com a coleção atual
  user.incomes.create!(
    date: current_month.change(day: rand(10..28)),
    value: rand(20.0..150.0).round(2),
    income_type: ["Vale", "Hora Extra", "Outros"].sample,
    description: "Entrada Avulsa"
  )

  # ==========================================
  # GASTOS (Expenses)
  # ==========================================

  # Despesas Fixas Todo Mês
  [
    { val: aluguel, type: "Moradia", desc: "Aluguel" },
    { val: condominio, type: "Moradia", desc: "Condomínio" },
    { val: plano_saude, type: "Saúde", desc: "Plano de Saúde SulAmérica" },
    { val: internet, type: "Moradia", desc: "Internet Fibra" },
    { val: rand(120.0..220.0).round(2), type: "Moradia", desc: "Conta de Energia" },
    { val: rand(60.0..100.0).round(2), type: "Moradia", desc: "Conta de Água" }
  ].each do |fixo|
    user.expenses.create!(
      date: current_month.change(day: rand(5..15)),
      value: fixo[:val],
      expense_type: fixo[:type],
      description: fixo[:desc]
    )
  end

  # Alimentação (Mercado toda semana + Padaria)
  4.times.each_with_index do |_, i|
    user.expenses.create!(
      date: current_month.change(day: 1 + (i * 7)),
      value: rand(250.0..450.0).round(2), # Mercado
      expense_type: "Alimentação",
      description: "Supermercado Semana #{i+1}"
    )
    # Padaria / iFood
    2.times do
      user.expenses.create!(
        date: current_month.change(day: rand(1..28)),
        value: rand(40.0..120.0).round(2),
        expense_type: "Alimentação",
        description: ["Padaria Pão Kent", "iFood Mcdonalds", "Hamburgueria", "Pizzaria delivery"].sample
      )
    end
  end

  # Transporte (Gasolina/Uber)
  4.times do
    user.expenses.create!(
      date: current_month.change(day: rand(1..28)),
      value: rand(40.0..180.0).round(2),
      expense_type: "Transporte",
      description: ["Posto Ipiranga", "Posto Shell", "Uber Viagem", "99App Corridas", "Mecânica (Prevenção)"].sample
    )
  end

  # Lazer (Final de semana, shows, assinaturas)
  user.expenses.create!(date: current_month.change(day: 5), value: 55.90, expense_type: "Lazer", description: "Assinatura Netflix Premium")
  user.expenses.create!(date: current_month.change(day: 10), value: 21.90, expense_type: "Lazer", description: "Assinatura Spotify")
  user.expenses.create!(date: current_month.change(day: 12), value: 39.90, expense_type: "Lazer", description: "Gympass / Academia")

  rand(2..5).times do
    user.expenses.create!(
      date: current_month.change(day: rand(10..28)),
      value: rand(80.0..450.0).round(2),
      expense_type: "Lazer",
      description: ["Cinema Cinemark VIP", "Bar com amigos", "Restaurante Especial FDS", "Show/Evento Ticket", "Compra de Jogo PS5", "Passeio Turístico / Viagem Curta"].sample
    )
  end

  # Pets, Educação, Cuidados, Taxas (aleatórios)
  if rand < 0.6
    user.expenses.create!(date: current_month.change(day: rand(5..28)), value: rand(150.0..300.0).round(2), expense_type: "Pets", description: "Ração Premium Golden")
  end
  if rand < 0.4
    user.expenses.create!(date: current_month.change(day: rand(5..28)), value: rand(120.0..800.0).round(2), expense_type: "Educação", description: ["Curso Udemy Promocional", "Livros Técnicos", "Mensalidade Curso de Idiomas", "Workshop"].sample)
  end
  user.expenses.create!(date: current_month.change(day: rand(5..28)), value: rand(60.0..250.0).round(2), expense_type: "Pessoal", description: ["Corte de Cabelo/Barba", "Vestuário / Perfume", "Produtos de Cuidados", "Farmácia Base"].sample)

  # ==========================================
  # INVESTIMENTOS (Investments)
  # ==========================================

  # Aporte Fixo em Reserva
  user.investments.create!(
    date: current_month.change(day: 10),
    value: 500.00,
    investment_type: "Renda Fixa",
    description: "Aporte Mensal para Reserva de Emergência",
    interest_rate: 11.5
  )

  # Diversificação do Mês
  rand(1..3).times do
    inv = [
      { t: "Fundos de Investimento", rate: rand(8.0..12.5), desc: ["FII de Logística", "FII de Shoppings", "Fundo Multimercado", "Fundo de Papel"].sample },
      { t: "Renda Variável", rate: rand(8.0..18.0), desc: ["Ações de Bancos", "Ações de Energia", "Ações de Tecnologia", "BDRs de Tecnologia"].sample },
      { t: "Renda Fixa", rate: rand(10.0..14.5), desc: ["CDB IPCA+", "Tesouro IPCA+", "LCI com Liquidez", "CDB Pós-fixado"].sample },
      { t: "Renda Variável", rate: rand(10.0..25.0), desc: ["Carteira Internacional", "BDR de Tecnologia", "ETF Global"].sample },
      { t: "Outros", rate: rand(15.0..60.0), desc: ["Cripto em custódia", "Alocação Tática", "Aporte Oportunístico"].sample },
      { t: "Previdência Privada", rate: rand(7.0..11.0), desc: "Contribuição PGBL" }
    ].sample

    user.investments.create!(
      date: current_month.change(day: rand(12..28)),
      value: rand(200.0..1500.0).round(2),
      investment_type: inv[:t],
      description: inv[:desc],
      interest_rate: inv[:rate].round(2)
    )
  end

  current_month = current_month.next_month
end

puts "Gerando Metas Inteligentes de Janeiro 2024 até Junho 2026..."

# Agora vamos gerar metas de mês a mês de 24 a meio de 26
goal_start_date = Date.new(2024, 1, 1)
goal_end_date = Date.new(2026, 6, 30)
current_goal_month = goal_start_date

while current_goal_month <= goal_end_date
  # Meta de Investimento
  user.goals.create!(
    description: "Aportes Longo Prazo",
    goal_type: "investment",
    target_value: rand(1500.0..3000.0).round(2),
    month: current_goal_month.month,
    year: current_goal_month.year
  )

  # Meta de Frear gastos
  user.goals.create!(
    description: "Limitar Gastos de Lazer a R$ 600",
    goal_type: "expense",
    target_value: 600.0,
    month: current_goal_month.month,
    year: current_goal_month.year,
    category: "Lazer"
  )

  # As vezes uma meta de renda (freelancers, vendas)
  if rand < 0.5
    user.goals.create!(
      description: "Tirar renda de Freelance Extra",
      goal_type: "savings",
      target_value: rand(800.0..1500.0).round(2),
      month: current_goal_month.month,
      year: current_goal_month.year
    )
  end

  # Viagens ou compras
  if [6, 7, 11, 12, 1].include?(current_goal_month.month)
    user.goals.create!(
      description: current_goal_month.month > 10 ? "Viagem de Fim de Ano" : "Férias de Julho",
      goal_type: "savings",
      target_value: rand(3000.0..6000.0).round(2),
      month: current_goal_month.month,
      year: current_goal_month.year
    )
  end

  current_goal_month = current_goal_month.next_month
end

puts "Seed finalizado com sucesso e requinte!"
puts "Estatísticas GERAIS para #{user.email}:"
puts "  - Rendas: #{user.incomes.count} registros"
puts "  - Gastos: #{user.expenses.count} registros"
puts "  - Investimentos: #{user.investments.count} registros"
puts "  - Metas Estabelecidas: #{user.goals.count} metas"
puts "Um total de #{user.incomes.count + user.expenses.count + user.investments.count + user.goals.count} artefatos financeiros criados de 2024 a meados 2026."
puts "Login: teste@mtracker.com / Senha: 123456"
