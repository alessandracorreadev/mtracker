class Investment < ApplicationRecord
  CATEGORIES = ["Renda Fixa", "Renda Variável", "Fundos de Investimento", "Previdência Privada", "Outros"].freeze

  belongs_to :user

  # Invalidate the AI system prompt cache when financial data changes
  after_commit -> { Rails.cache.delete("ai_context_#{user_id}") }

  def current_value
    value_at(Date.today)
  end

  def value_at(target_date)
    return value if target_date <= date
    return value unless interest_rate.present? && interest_rate > 0

    # Number of days elapsed
    days = (target_date - date).to_i
    return value if days <= 0

    # Daily compounding based on annual rate
    daily_rate = (interest_rate / 100.0) / 365.0
    (value * (1 + daily_rate)**days).round(2)
  end

  def yield_in_period(start_date, end_date)
    # The yield earned within this specific window of time
    # (Value at end of month) - (Value at start of month or investment date)
    initial_checkpoint = [start_date, date].max
    
    val_end   = value_at(end_date)
    val_start = value_at(initial_checkpoint)
    
    (val_end - val_start).round(2)
  end

  def accumulated_yield
    (current_value - value).round(2)
  end

  validates :value, :date, :description, :investment_type, presence: true
  validates :value, numericality: { greater_than: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
