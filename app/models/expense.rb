class Expense < ApplicationRecord
  belongs_to :user

  validates :value, :date, :description, :expense_type, presence: true
  validates :value, numericality: { greater_than: 0 }
end
