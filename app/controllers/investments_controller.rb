class InvestmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_investment, only: [:show, :edit, :update, :destroy]

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

  def investment_params
    params.require(:investment).permit(:description, :value, :date, :investment_type)
  end
end
