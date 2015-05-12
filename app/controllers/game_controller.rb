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

  def join
    # try to find game
    game = Game.find_by(uuid: params[:game_id])
    if game
      # game found
      player = game.players.create(nick: params[:nick])
      render json: {
        registered: true,
        player_id: player.uuid,
        nick: player.nick,
      }
    else
      # game not found
      render status: :not_found, json: {
        registered: false,
        player_id: nil,
        nick: nil,
      }
    end
  end

end
