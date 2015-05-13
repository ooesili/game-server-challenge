class Game < ActiveRecord::Base
  validates :board, :uuid, presence: true
  after_initialize :set_defaults, if: :new_record?
  belongs_to :creator, class: Player, foreign_key: 'creator_id'
  before_destroy :remove_creator
  has_many :players, dependent: :destroy

  private

  def set_defaults
    self.board = NewGameHelper.new_game(15, 10)
    self.uuid = SecureRandom.uuid
  end

  def remove_creator
    self.creator_id = nil
    self.save!
  end

end
