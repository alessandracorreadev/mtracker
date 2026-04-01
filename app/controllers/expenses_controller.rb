class ExpensesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_expense, only: [:edit, :update, :destroy]

  def index
    @expense = current_user.expenses.new
    
    @selected_year  = params[:year].present?  ? params[:year].to_i  : Date.current.year
    @selected_month = params[:month].present? ? params[:month].to_i : Date.current.month
    @is_filtered = params[:month].present? || params[:year].present?

    if @is_filtered
      start_date = Date.new(@selected_year, @selected_month, 1)
      end_date   = start_date.end_of_month
      @expenses = current_user.expenses.where(date: start_date..end_date).order(date: :desc)
    else
      @expenses = current_user.expenses.order(date: :desc)
    end

    @expenses_by_month = @expenses.group_by { |e| e.date.beginning_of_month }.sort_by { |month, _| month }.reverse

    @years  = (2020..Date.current.year).to_a.reverse
    month_names = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
    @months = (1..12).map { |m| [month_names[m - 1], m] }
  end

  def new
    @expense = current_user.expenses.new
  end

  def create
    @expense = current_user.expenses.new(expense_params)
    if @expense.save
      redirect_to expenses_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path
    else
      render :edit
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end


  def expense_params
    params.require(:expense).permit(:description, :value, :date, :expense_type)
  end
end
