class Expense < ApplicationRecord
  belongs_to :user

  # Invalidate the AI system prompt cache when financial data changes
  after_commit -> { Rails.cache.delete("ai_context_#{user_id}") }

  validates :value, :date, :description, :expense_type, presence: true
  validates :value, numericality: { greater_than: 0 }
end
