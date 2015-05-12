class GameController < ApplicationController

  def create
    # create game and player
    game = Game.create
    player = game.players.create(nick: params[:nick])
    # respond with appropriate data
    render json: {
      game_id: game.uuid,
      player_id: player.uuid,
      nick: player.nick,
    }
  end

end
