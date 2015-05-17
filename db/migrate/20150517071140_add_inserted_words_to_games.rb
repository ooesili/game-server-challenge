class AddInsertedWordsToGames < ActiveRecord::Migration
  def change
    add_column :games, :inserted_words, :json, null: false, default: []
  end
end
