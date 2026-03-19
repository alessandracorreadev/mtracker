class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :destroy]

  def index
    # Singleton chat per user
    @chat = current_user.chats.first_or_create!
    redirect_to @chat
  end

  def show
  end

  def create
    @chat = current_user.chats.first_or_create!
    redirect_to @chat
  end

  def destroy
    @chat.destroy
    redirect_to dashboard_path, notice: "Chat history cleared."
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
