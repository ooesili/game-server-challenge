class AddUuidsToPlayersAndGames < ActiveRecord::Migration
  def change
    add_column :games, :uuid, :string
    add_column :players, :uuid, :string
  end
end
