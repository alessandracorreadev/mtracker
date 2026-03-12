class AddChatIdToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :chat_id, :integer
  end
end
