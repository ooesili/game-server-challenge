class Game < ActiveRecord::Base
  validates :board, presence: true
  after_initialize :set_board, if: :new_record?
  has_many :players, dependent: :destroy

  private

  def set_board
    self.board = NewGameHelper.new_game(15, 10)
  end

end
