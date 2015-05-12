class Player < ActiveRecord::Base
  validates :nick, :score, presence: true
  belongs_to :game
  after_initialize :set_defaults, if: :new_record?

  private

  def set_defaults
    self.nick = Faker::Internet.domain_word if self.nick.nil?
    self.score = 0
  end
end
