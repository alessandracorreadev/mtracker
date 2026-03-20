class AddInterestRateToInvestments < ActiveRecord::Migration[7.1]
  def change
    add_column :investments, :interest_rate, :decimal, precision: 8, scale: 4
  end
end
