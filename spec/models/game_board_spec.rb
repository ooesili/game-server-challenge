require 'rails_helper'

RSpec.describe GameBoard, type: :model do

  describe '#fill_board' do
    before(:each) do
      subject.fill_board(15, 10)
    end
    it 'contains all of the inserted words' do
      all_found = subject.inserted_words.all? do |word|
        subject.find_word(word)
      end
      expect(all_found).to be(true)
    end
  end

end
