class AddUserIdToChats < ActiveRecord::Migration[7.1]
  def change
    add_column :chats, :user_id, :integer
  end
end
