class IncomesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_income, only: [:edit, :update, :destroy]
  before_action :set_existing_income_types, only: [:new, :create, :edit, :update]

  def index
    @selected_year  = params[:year].present?  ? params[:year].to_i  : Date.current.year
    @selected_month = params[:month].present? ? params[:month].to_i : Date.current.month
    @is_filtered = params[:month].present? || params[:year].present?

    if @is_filtered
      start_date = Date.new(@selected_year, @selected_month, 1)
      end_date   = start_date.end_of_month
      @incomes = current_user.incomes.where(date: start_date..end_date).order(date: :desc)
    else
      @incomes = current_user.incomes.order(date: :desc)
    end

    @incomes_by_month = @incomes.group_by { |i| i.date.beginning_of_month }.sort_by { |month, _| month }.reverse

    @years  = (2020..Date.current.year).to_a.reverse
    month_names = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
    @months = (1..12).map { |m| [month_names[m - 1], m] }
  end

  def new
    @income = current_user.incomes.new
  end

  def create
    @income = current_user.incomes.new(income_params)
    if @income.save
      redirect_to incomes_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @income.update(income_params)
      redirect_to incomes_path
    else
      render :edit
    end
  end

  def destroy
    @income.destroy
    redirect_to incomes_path
  end

  private

  def set_income
    @income = current_user.incomes.find(params[:id])
  end

  def set_existing_income_types
    @existing_income_types = current_user.incomes
      .where.not(income_type: [nil, ""])
      .distinct
      .pluck(:income_type)
      .sort
  end

  def income_params
    params.require(:income).permit(:description, :value, :date, :income_type)
  end
end
