class CreateIncomes < ActiveRecord::Migration[7.1]
  def change
    create_table :incomes do |t|
      t.date :date
      t.decimal :value
      t.string :income_type
      t.string :description

      t.timestamps
    end
  end
end
