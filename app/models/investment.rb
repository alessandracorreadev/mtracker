class Investment < ApplicationRecord
  belongs_to :user

  validates :value, :date, :description, :investment_type, presence: true
  validates :value, numericality: { greater_than: 0 }
end
