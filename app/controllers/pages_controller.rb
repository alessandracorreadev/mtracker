class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home
  layout "dashboard", only: :index

  def home
  end

  def index
    @selected_year  = params[:year].present?  ? params[:year].to_i  : Date.current.year
    @selected_month = params[:month].present? ? params[:month].to_i : Date.current.month

    start_date = Date.new(@selected_year, @selected_month, 1)
    end_date   = start_date.end_of_month

    @expenses    = current_user.expenses.where(date: start_date..end_date)
    @incomes     = current_user.incomes.where(date: start_date..end_date)
    @investments = current_user.investments.where(date: start_date..end_date)

    @total_expenses    = @expenses.sum(:value)
    @total_incomes     = @incomes.sum(:value)
    @total_investments = @investments.sum(:value)
    @balance           = @total_incomes - @total_expenses - @total_investments

    @expenses_by_category = @expenses
      .where.not(expense_type: [nil, ""])
      .group(:expense_type)
      .sum(:value)
      .map { |name, total| { name: name, total: total } }

    @incomes_by_category = @incomes
      .where.not(income_type: [nil, ""])
      .group(:income_type)
      .sum(:value)
      .map { |name, total| { name: name, total: total } }

    @investments_by_category = @investments
      .where.not(investment_type: [nil, ""])
      .group(:investment_type)
      .sum(:value)
      .map { |name, total| { name: name, total: total } }

    @period_goals = current_user.goals.where(month: @selected_month, year: @selected_year)

    @years  = (2020..Date.current.year).to_a.reverse
    month_names = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
    @months = (1..12).map { |m| [month_names[m - 1], m] }

    @chart_colors = ["#10b981", "#3b82f6", "#8b5cf6", "#f59e0b", "#ef4444",
                     "#06b6d4", "#ec4899", "#20c997", "#64748b"]
  end
end
