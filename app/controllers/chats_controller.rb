class ChatsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat, only: [:show, :destroy]

  def index
    @chats = current_user.chats
  end

  def show
  end

  def create
    @chat = current_user.chats.create!
    redirect_to @chat
  end

  def destroy
    @chat.destroy
    redirect_to chats_path
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end
end
