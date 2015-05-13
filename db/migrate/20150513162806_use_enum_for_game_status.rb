class UseEnumForGameStatus < ActiveRecord::Migration
  def change
    remove_column :games, :started, :boolean, default: 0, null: false
    add_column :games, :status, :integer, default: 0, null: false
  end
end
