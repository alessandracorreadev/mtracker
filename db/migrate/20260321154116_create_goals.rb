class CreateGoals < ActiveRecord::Migration[7.1]
  def change
    create_table :goals do |t|
      t.string :description
      t.string :goal_type
      t.decimal :target_value, precision: 15, scale: 2
      t.integer :month
      t.integer :year
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
