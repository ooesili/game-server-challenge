class AddTurnToGames < ActiveRecord::Migration
  def change
    add_column :games, :turn, :integer, default: 0, null: false
  end
end
