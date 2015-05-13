class GameController < ApplicationController

  def create
    # create game and player
    game = Game.new
    player = game.players.new(nick: params[:nick])
    game.creator = player
    game.save
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

  def start
    # try to find game
    game = Game.find_by(uuid: params[:game_id])
    # make sure the game exists
    if not game
      render json: {
        success: false,
        message: 'game not found',
        grid: [],
      }
      return
    end
    # try to find player
    player = game.players.find_by(uuid: params[:player_id])
    # make sure the player exists
    if not player
      render json: {
        success: false,
        message: 'player not found',
        grid: [],
      }
      return
    end
    # make sure the creator is trying to start the game
    if player != game.creator
      render json: {
        success: false,
        message: 'you are not the creator of the game',
        grid: [],
      }
      return
    end
    # see if game is already started
    if game.started
      render json: {
        success: false,
        message: 'game already started',
        grid: [],
      }
      return
    end
    # success
    game.update(started: true)
    render json: {
      success: true,
      message: 'all good',
      grid: game.board,
    }
  end

end
