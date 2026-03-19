class Investment < ApplicationRecord
  belongs_to :user

  validates :value, :date, :description, :investment_type, presence: true
  validates :value, numericality: { greater_than: 0 }
  validates :interest_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
