class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy]
  before_action :set_existing_expense_types, only: [:new, :create, :edit, :update]

  def index
    @expenses = current_user.expenses
  end

  def show
  end

  def new
    @expense = current_user.expenses.new
  end

  def create
    @expense = current_user.expenses.new(expense_params)
    if @expense.save
      redirect_to @expense
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @expense.update(expense_params)
      redirect_to @expense
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

  def set_existing_expense_types
    @existing_expense_types = current_user.expenses
      .where.not(expense_type: [nil, ""])
      .distinct
      .pluck(:expense_type)
      .sort
  end

  def expense_params
    params.require(:expense).permit(:description, :value, :date, :expense_type)
  end
end
