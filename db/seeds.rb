# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding..."

user = User.find_or_initialize_by(email: "teste@mtracker.com")
if user.new_record?
  user.assign_attributes(
    password: "123456",
    password_confirmation: "123456",
    name: "Usuário Teste",
    birth_date: Date.new(1990, 5, 15)
  )
  user.save!
  puts "  Criado usuário: #{user.email} (senha: 123456)"
else
  puts "  Usuário já existe: #{user.email}"
end

if user.expenses.exists?
  puts "  Dados já existem para este usuário. Nada mais a criar."
else
  base = Date.current

  expense_categories = ["Alimentação", "Transporte", "Moradia", "Lazer", "Saúde", "Compras"]
  [-2, -1, 0].each do |m|
    d = base + m.months
    expense_categories.sample(4).each_with_index do |cat, i|
      user.expenses.create!(
        date: d - i.days,
        value: [29.90, 45.00, 120.00, 89.50, 35.00, 200.00].sample,
        expense_type: cat,
        description: "Gasto em #{cat.downcase}"
      )
    end
  end

  income_categories = ["Salário", "Freelance", "Investimentos", "Extra"]
  [-2, -1, 0].each do |m|
    user.incomes.create!(
      date: base + m.months + 5.days,
      value: [3500.00, 1200.00].sample,
      income_type: income_categories.sample,
      description: m.zero? ? "Renda do mês" : "Renda mês anterior"
    )
  end

  investment_categories = ["Renda fixa", "Ações", "Tesouro Direto", "FII"]
  [-1, 0].each do |m|
    user.investments.create!(
      date: base + m.months + 10.days,
      value: [500.00, 1000.00, 300.00].sample,
      investment_type: investment_categories.sample,
      description: "Aplicação"
    )
  end

  puts "  Criados: #{user.expenses.count} gastos, #{user.incomes.count} ganhos, #{user.investments.count} investimentos."
end

puts "Seed concluído."
puts "  Login: teste@mtracker.com / 123456"
