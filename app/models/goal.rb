class Goal < ApplicationRecord
  belongs_to :user

  TYPES = {
    "savings"    => "Economizar",
    "expense"    => "Limite de gastos",
    "investment" => "Investir"
  }.freeze

  validates :description, :goal_type, :target_value, :month, :year, presence: true
  validates :target_value, numericality: { greater_than: 0 }
  validates :month, inclusion: { in: 1..12 }
  validates :goal_type, inclusion: { in: TYPES.keys }

  def current_value
    case goal_type
    when "savings"
      user.incomes.where(month_year_scope).sum(:value) -
        user.expenses.where(month_year_scope).sum(:value)
    when "expense"
      user.expenses.where(month_year_scope).sum(:value)
    when "investment"
      user.investments.where(month_year_scope).sum(:value)
    end
  end

  def achieved?
    case goal_type
    when "savings", "investment"
      current_value >= target_value
    when "expense"
      current_value <= target_value
    end
  end

  def progress_percent
    return 100 if achieved?
    return 0 if target_value.zero?

    case goal_type
    when "savings", "investment"
      [(current_value / target_value * 100).round, 100].min
    when "expense"
      # Para limite de gastos, progresso é quanto do limite já foi usado
      [(current_value / target_value * 100).round, 100].min
    end
  end

  def type_label
    TYPES[goal_type] || goal_type
  end

  def month_name
    Date::MONTHNAMES[month]
  end

  private

  def month_year_scope
    { date: Date.new(year, month, 1).beginning_of_month..Date.new(year, month, 1).end_of_month }
  end
end
