class Game < ActiveRecord::Base
  validates :board, :uuid, presence: true
  belongs_to :creator, class: Player, foreign_key: 'creator_id'
  before_destroy :remove_creator
  has_many :players, dependent: :destroy
  enum status: ['Waiting', 'In Play', 'Completed']

  def current_player
    self.players.order(:id)[self.turn]
  end

  def play!(word)
    # make sure the word hasn't already been found
    game_board = GameBoard.new(self.board)
    if not words_done.include? word and game_board.find_word word
      word_size = word.size
      # record word as found
      words_done.push word
      # increment the current player's score
      player = current_player
      player.score += word_size
      player.save!
      # finish the turn
      next_turn(game_board)
      word_size
    else
      0
    end
  end

  def self.build(size = 15, num_words = 10)
    # create board
    game_board = GameBoard.new
    game_board.fill_board(size, num_words)
    # create game
    game = new
    game.board = game_board.board
    game.uuid = SecureRandom.uuid
    game
  end

  private

  def remove_creator
    self.creator_id = nil
    self.save!
  end

  def next_turn(game_board)
    if (game_board.inserted_words - words_done).empty?
      self.update(status: 'Completed')
    else
      self.update(turn: (turn + 1) % self.players.size)
    end
  end

end
