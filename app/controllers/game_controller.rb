class GameController < ApplicationController

  def create
    # create game and player
    game = Game.build
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
    if not game or game.status != 'Waiting'
      # game not found or already started
      render status: :not_found, json: {
        registered: false,
        player_id: nil,
        nick: nil,
      }
      return
    end
    # game found
    player = game.players.create(nick: params[:nick])
    render json: {
      registered: true,
      player_id: player.uuid,
      nick: player.nick,
    }
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
    if game.status != 'Waiting'
      render json: {
        success: false,
        message: 'game already started',
        grid: [],
      }
      return
    end
    # success
    game.update!(status: 'In Play')
    render json: {
      success: true,
      message: 'all good',
      grid: game.board.board,
    }
  end

  def info
    # find game
    game = Game.find_by(uuid: params[:game_id])
    if not game
      render status: :not_found, json: {
        message: 'game not found'
      }
      return
    end
    # find player
    player = game.players.find_by(uuid: params[:player_id])
    if not player
      render status: :not_found, json: {
        message: 'player not found'
      }
      return
    end
    # render information
    players = game.players
    render json: {
      game_status: game.status,
      current_player: game.current_player.nick,
      turn_seq: players.pluck(:nick).rotate(game.turn),
      words_done: game.words_done,
      scores: players.pluck(:nick, :score).to_h,
      grid: game.board.board,
    }
  end

  def play
    # find game
    game = Game.find_by(uuid: params[:game_id])
    if not game
      render status: :not_found, json: {
        message: 'game not found'
      }
      return
    end
    # find player
    player = game.players.find_by(uuid: params[:player_id])
    if not player
      render status: :not_found, json: {
        message: 'player not found'
      }
      return
    end
    if game.current_player != player
      render json: {
        success: false,
        score: 0,
      }
      return
    end
    # make sure we got a word
    word = params[:word]
    if word.nil?
      score = 0
    else
      score = game.play!(word)
    end
    render json: {
      success: score > 0,
      score: score,
    }
  end

end
