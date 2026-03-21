class AddCategoryToGoals < ActiveRecord::Migration[7.1]
  def change
    add_column :goals, :category, :string
  end
end
