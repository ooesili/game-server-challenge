class LetCreatorsStartGames < ActiveRecord::Migration
  def change
    add_column :games, :started, :boolean, default: false, null: false
    add_column :games, :creator_id, :integer, index: true
    add_foreign_key :games, :players, column: :creator_id
  end
end
