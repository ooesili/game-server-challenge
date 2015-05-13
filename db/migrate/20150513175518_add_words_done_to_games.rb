class AddWordsDoneToGames < ActiveRecord::Migration
  def change
    add_column :games, :words_done, :json, default: [], null: false
  end
end
