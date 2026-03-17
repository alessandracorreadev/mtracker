class InvestmentsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_investment, only: [:show, :edit, :update, :destroy]
  before_action :set_existing_investment_types, only: [:new, :create, :edit, :update]

  def index
    @investments = current_user.investments
  end

  def show
  end

  def new
    @investment = current_user.investments.new
  end

  def create
    @investment = current_user.investments.new(investment_params)
    if @investment.save
      redirect_to @investment
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @investment.update(investment_params)
      redirect_to @investment
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
    params.require(:investment).permit(:description, :value, :date, :investment_type)
  end
end
