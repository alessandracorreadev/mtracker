class InvestmentsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_investment, only: [:edit, :update, :destroy]
  before_action :set_existing_investment_types, only: [:new, :create, :edit, :update]

  def index
    @investment = current_user.investments.new
    
    @selected_year  = params[:year].present?  ? params[:year].to_i  : Date.current.year
    @selected_month = params[:month].present? ? params[:month].to_i : Date.current.month
    @is_filtered = params[:month].present? || params[:year].present?

    if @is_filtered
      start_date = Date.new(@selected_year, @selected_month, 1)
      end_date   = start_date.end_of_month
      @investments = current_user.investments.where(date: start_date..end_date).order(date: :desc)
    else
      @investments = current_user.investments.order(date: :desc)
    end

    @investments_by_month = @investments.group_by { |i| i.date.beginning_of_month }.sort_by { |month, _| month }.reverse

    @years  = (2020..Date.current.year).to_a.reverse
    month_names = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro]
    @months = (1..12).map { |m| [month_names[m - 1], m] }
  end

  def returns
    redirect_back(fallback_location:dashboard_path) unless Flipper.enabled?(:returns_investments)

    @investments = current_user.investments.order(date: :desc)
    @investments_by_type = @investments.group_by(&:investment_type)

    @total_invested = @investments.sum(:value)
    @total_current_value = @investments.map(&:current_value).sum
    @total_yield = @total_current_value - @total_invested

    # Portfolio KPIs
    total_incomes = current_user.incomes.sum(:value) || 0
    total_expenses = current_user.expenses.sum(:value) || 0
    @savings_rate = total_incomes > 0 ? (((total_incomes - total_expenses) / total_incomes) * 100).round(1) : 0
    @portfolio_yield_pct = @total_invested > 0 ? ((@total_yield / @total_invested) * 100).round(2) : 0


    # Estimativa de rendimento mensal (próximo mês)
    # Usa taxa mensal equivalente para juros compostos: (1 + i_anual)^(1/12) - 1
    @monthly_estimated_yield = @investments.sum do |inv|
      if inv.interest_rate.present? && inv.interest_rate > 0
        annual_rate = inv.interest_rate / 100.0
        monthly_rate = (1 + annual_rate)**(1.0 / 12) - 1
        inv.current_value * monthly_rate
      else
        0
      end
    end
  end

  def new
    @investment = current_user.investments.new
  end

  def create
    @investment = current_user.investments.new(investment_params)
    if @investment.save
      redirect_to investments_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @investment.update(investment_params)
      redirect_to investments_path
    else
      render :edit
    end
  end

  def destroy
    @investment.destroy
    redirect_to investments_path
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:id])
  end

  def set_existing_investment_types
    @existing_investment_types = current_user.investments
      .where.not(investment_type: [nil, ""])
      .distinct
      .pluck(:investment_type)
      .sort
  end

  def investment_params
    params.require(:investment).permit(:description, :value, :date, :investment_type, :interest_rate)
  end
end
