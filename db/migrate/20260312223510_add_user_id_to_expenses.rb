class AddUserIdToExpenses < ActiveRecord::Migration[7.1]
  def change
    add_column :expenses, :user_id, :integer
  end
end
