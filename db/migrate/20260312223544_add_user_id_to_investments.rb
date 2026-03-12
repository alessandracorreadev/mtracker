class AddUserIdToInvestments < ActiveRecord::Migration[7.1]
  def change
    add_column :investments, :user_id, :integer
  end
end
