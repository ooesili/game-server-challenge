class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :nick
      t.integer :score
      t.belongs_to :game, index: true
    end
    add_foreign_key :players, :games
  end
end
