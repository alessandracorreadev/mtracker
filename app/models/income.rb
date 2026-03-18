class Income < ApplicationRecord
  belongs_to :user

  validates :value, :date, :description, :income_type, presence: true
  validates :value, numericality: { greater_than: 0 }
end
