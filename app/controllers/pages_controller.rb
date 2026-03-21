class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home
  layout "dashboard", only: :index

  def home
  end

  def index
    filter_all = params[:month].to_s == "all"
    @selected_year = params[:year].present? ? params[:year].to_i : Date.current.year
    @selected_year = [[@selected_year, 1].max, 9999].min
    @selected_month = filter_all ? "all" : (params[:month].present? ? params[:month].to_i : Date.current.month)
    @selected_month = [[@selected_month, 1].max, 12].min if @selected_month.is_a?(Integer)
    
    @chart_colors = [
      "#10b981", "#3b82f6", "#8b5cf6", "#f59e0b", "#ef4444", 
      "#06b6d4", "#ec4899", "#8b5cf6", "#20c997", "#64748b"
    ]

    if filter_all
      @expenses = current_user.expenses
      @incomes = current_user.incomes
      @investments = current_user.investments
    else
      start_date = Date.new(@selected_year, @selected_month, 1)
      end_date = start_date.end_of_month
      range = start_date..end_date
      @expenses = current_user.expenses.where(date: range)
      @incomes = current_user.incomes.where(date: range)
      @investments = current_user.investments.where(date: range)
    end

    @total_expenses = @expenses.sum(:value) || 0
    @total_incomes = @incomes.sum(:value) || 0
    @total_investments = @investments.map(&:current_value).sum || 0
    @total_yield = @total_investments - (@investments.sum(:value) || 0)
    @balance = @total_incomes - @total_expenses

    @expenses_by_category = @expenses
      .where.not(expense_type: [nil, ""])
      .group(:expense_type)
      .sum(:value)
      .map { |name, total| { name: name, total: total } }

    @investments_by_category = @investments
      .where.not(investment_type: [nil, ""])
      .group(:investment_type)
      .sum(:value)
      .map { |name, total| { name: name, total: total } }

    first_year = [current_user.expenses.minimum(:date)&.year, current_user.incomes.minimum(:date)&.year, current_user.investments.minimum(:date)&.year].compact.min || Date.current.year
    @years = (first_year..Date.current.year).to_a.reverse
    month_names = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
    @months = [["Todos os meses", "all"]] + (1..12).map { |m| [month_names[m - 1], m] }
  end
end
