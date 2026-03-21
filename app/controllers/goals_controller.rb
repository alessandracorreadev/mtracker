class GoalsController < ApplicationController
  layout "dashboard"
  before_action :authenticate_user!
  before_action :set_goal, only: [:edit, :update, :destroy]

  def index
    @goals = current_user.goals.order(year: :desc, month: :desc, created_at: :desc)
  end

  def new
    @goal = Goal.new(month: Date.today.month, year: Date.today.year)
  end

  def create
    @goal = current_user.goals.build(goal_params)
    if @goal.save
      redirect_to goals_path, notice: "Meta criada com sucesso!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @goal.update(goal_params)
      redirect_to goals_path, notice: "Meta atualizada com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to goals_path, notice: "Meta removida."
  end

  private

  def set_goal
    @goal = current_user.goals.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:description, :goal_type, :target_value, :month, :year, :category)
  end
end
