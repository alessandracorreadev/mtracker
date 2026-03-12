class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
  end

  def index
    @expenses = current_user.expenses
    @incomes = current_user.incomes
    @investments = current_user.investments
  end
end
