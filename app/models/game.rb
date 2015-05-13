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

  def self.build(size = 15, num_words = 10)
    game = new
    game.board.fill_board(size, num_words)
    game.uuid = SecureRandom.uuid
    game
  end

  private

  def remove_creator
    self.creator_id = nil
    self.save!
  end

end
