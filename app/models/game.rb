class Game < ActiveRecord::Base
  validates :board, :uuid, presence: true
  after_initialize :set_defaults, if: :new_record?
  has_many :players, dependent: :destroy

  private

  def set_defaults
    self.board = NewGameHelper.new_game(15, 10)
    self.uuid = SecureRandom.uuid
  end

end
