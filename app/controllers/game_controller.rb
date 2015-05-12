class GameController < ApplicationController

  def create
    game = NewGameHelper.new_game(15, 10)
    render json: game
  end

end
