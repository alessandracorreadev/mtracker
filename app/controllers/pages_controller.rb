class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home
  layout "dashboard", only: :index

  def home
  end

  def index
    @expenses = current_user.expenses
    @incomes = current_user.incomes
    @investments = current_user.investments

    @total_expenses = @expenses.sum(:value) || 0
    @total_incomes = @incomes.sum(:value) || 0
    @total_investments = @investments.sum(:value) || 0
    @balance = @total_incomes - @total_expenses

    @expenses_by_category = @expenses
      .where.not(expense_type: [nil, ""])
      .group(:expense_type)
      .sum(:value)
      .map { |name, total| { name: name, total: total } }
  end
end
