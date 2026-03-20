class Message < ApplicationRecord
  belongs_to :chat

  validates :content, presence: true, if: -> { role == "user" }
  
  # Action Cable broadcasting
  after_create_commit :broadcast_append_to_chat

  private

  def broadcast_append_to_chat
    # Broadcast to the chat-specific channel
    broadcast_append_to chat, target: "messages", partial: "messages/message", locals: { message: self }
  end
end
