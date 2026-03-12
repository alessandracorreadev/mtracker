class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.date :date
      t.decimal :value
      t.string :expense_type
      t.string :description

      t.timestamps
    end
  end
end
