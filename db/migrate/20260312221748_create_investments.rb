class CreateInvestments < ActiveRecord::Migration[7.1]
  def change
    create_table :investments do |t|
      t.date :date
      t.decimal :value
      t.string :investment_type
      t.string :description

      t.timestamps
    end
  end
end
