require 'rails_helper'

fake_board = [
  'ZURQIXJCDTTSOSG',
  'UNYQMTETAILOFIB',
  'GFENTYSOTCQRSSO',
  'RRXODNIUUODHIUB',
  'EUMIOOOANCEESOI',
  'WCPTMMPBNRISONA',
  'OTEAKRRICHFINOY',
  'RUGZXAEYZXOSITB',
  'GOSIMHVCAPROPOM',
  'EUMHXEOSRVMTYMB',
  'LSYCHRWNSDIIHOU',
  'PVZEAPDQHDTMJHD',
  'PMETTSNWIUYUFNK',
  'AEKAQJWXPOXEIUG',
  'BWACRAODUROFTJW',
].map(&:chars)

RSpec.describe GameController, type: :controller do

  before(:each) do
    # create a predictable board
    game_board = GameBoard.new fake_board
    # ignore fill_board calls
    allow(game_board).to receive('fill_board')
    # inject the created game_board
    allow(GameBoard).to receive(:new).and_return(game_board)
  end

  describe '#create' do
    # create a new game
    before(:each) do
      get :create
      @data = JSON.parse(response.body)
      @game = Game.find_by(uuid: @data['game_id'])
      @creator = @game.players.find_by(uuid: @data['player_id'])
    end
    it 'creates a new game' do
      expect(@game).to be
    end
    it 'creates a single player' do
      expect(@game.players.size).to eq(1)
    end
    it 'create a new player' do
      expect(@game.players.first.id).to eq(@creator.id)
    end
    it 'sets the game\'s creator' do
      expect(@game.creator.id).to be(@creator.id)
    end
  end

end
