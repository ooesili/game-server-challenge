class SetDefaultValueForScoreOnPlayers < ActiveRecord::Migration
  def change
    change_column :players, :score, :integer, default: 0, null: false
  end
end
