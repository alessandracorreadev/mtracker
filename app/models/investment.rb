class Investment < ApplicationRecord
  belongs_to :user

  def current_value
    return value unless interest_rate.present? && interest_rate > 0

    # Calcula meses entre a data do investimento e hoje
    months = (Date.today.year * 12 + Date.today.month) - (date.year * 12 + date.month)
    return value if months <= 0

    # Juros compostos mensais baseados na taxa anual
    monthly_rate = (interest_rate / 100.0) / 12.0
    (value * (1 + monthly_rate)**months).round(2)
  end

  def accumulated_yield
    current_value - value
  end

  validates :value, :date, :description, :investment_type, presence: true
  validates :value, numericality: { greater_than: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
