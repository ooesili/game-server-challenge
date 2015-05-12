class GameController < ApplicationController

  def create
    render json: Game.create
  end

end
