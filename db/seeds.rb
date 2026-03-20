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

puts "Gerando dados de Março 2025 até Março 2026..."

start_date = Date.new(2025, 3, 1)
end_date = Date.new(2026, 3, 31)
current_month = start_date

while current_month <= end_date
  # --- RENDAS (Incomes) ---
  # Salário mensal fixo
  user.incomes.create!(
    date: current_month.change(day: 5),
    value: 5000.00,
    income_type: "Salário",
    description: "Salário Mensal - #{current_month.strftime('%B %Y')}"
  )

  # Freelance ocasional (em alguns meses)
  if [true, false].sample
    user.incomes.create!(
      date: current_month.change(day: 20),
      value: [400, 600, 850].sample,
      income_type: "Freelance",
      description: "Projeto Extra"
    )
  end

  # --- GASTOS (Expenses) ---
  # Moradia (Fixo)
  user.expenses.create!(
    date: current_month.change(day: 10),
    value: 1500.00,
    expense_type: "Moradia",
    description: "Aluguel + Condomínio"
  )

  # Alimentação (Vários gastos no mês)
  4.times.each_with_index do |_, i|
    user.expenses.create!(
      date: current_month.change(day: 5 + (i * 7)),
      value: rand(150.0..350.0).round(2),
      expense_type: "Alimentação",
      description: "Supermercado Semana #{i+1}"
    )
  end

  # Transporte (Posto de gasolina/Uber)
  3.times do 
    user.expenses.create!(
      date: current_month.change(day: rand(1..28)),
      value: rand(50.0..120.0).round(2),
      expense_type: "Transporte",
      description: "Combustível / Uber"
    )
  end

  # Lazer (Final de semana)
  user.expenses.create!(
    date: current_month.change(day: rand(15..25)),
    value: rand(100.0..400.0).round(2),
    expense_type: "Lazer",
    description: "Jantar / Cinema"
  )

  # Saúde (Ocasional)
  if current_month.month % 3 == 0
    user.expenses.create!(
      date: current_month.change(day: 15),
      value: rand(100.0..250.0).round(2),
      expense_type: "Saúde",
      description: "Farmácia / Consulta"
    )
  end

  # --- INVESTIMENTOS ---
  user.investments.create!(
    date: current_month.change(day: 12),
    value: 500.00,
    investment_type: "Renda Fixa",
    description: "Aporte Mensal Tesouro",
    interest_rate: 0.12 # 12% ao ano
  )

  current_month = current_month.next_month
end

puts "Seed finalizado com sucesso!"
puts "Estatísticas para #{user.email}:"
puts "  - Incomes: #{user.incomes.count}"
puts "  - Expenses: #{user.expenses.count}"
puts "  - Investments: #{user.investments.count}"
puts "Login: teste@mtracker.com / 123456"
