class Game < ActiveRecord::Base
  validates :board, :uuid, presence: true
  belongs_to :creator, class: Player, foreign_key: 'creator_id'
  before_destroy :remove_creator
  has_many :players, dependent: :destroy
  enum status: ['Waiting', 'In Play', 'Completed']
  serialize :board, GameBoard

  def current_player
    self.players.order(:id)[self.turn]
  end

  def play!(word)
    # make sure the word hasn't already been found
    if not words_done.include? word and board.find_word word
      word_size = word.size
      # record word as found
      words_done.push word
      # increment the current player's score
      player = current_player
      player.score += word_size
      player.save!
      # finish the turn
      next_turn
      word_size
    else
      0
    end
  end

  def self.build(size = 15, num_words = 10)
    game = new
    game.board.fill_board(size, num_words)
    game.uuid = SecureRandom.uuid
    game
  end

  private

  def set_defaults
    self.board = NewGameHelper.new_game(15, 10)
    self.uuid = SecureRandom.uuid
  end

  private

  def remove_creator
    self.creator_id = nil
    self.save!
  end

  def next_turn
    if (self.board.inserted_words - words_done).empty?
      self.update(status: 'Completed')
    else
      self.update(turn: (turn + 1) % self.players.size)
    end
  end

end
