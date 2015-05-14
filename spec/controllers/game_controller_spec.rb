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

  describe '#join' do
    context 'with an unstarted game' do
      before(:each) do
        @game = create(:game)
      end
      context 'without a custom nick' do
        before(:each) do
          get :join, {game_id: @game.uuid}
          @data = JSON.parse(response.body)
        end
        it 'creates a new player who is part of the game' do
          new_player = Player.find_by(uuid: @data['player_id'])
          expect(new_player.game.id).to eq(@game.id)
        end
        it 'reports that registration is true' do
          expect(@data['registered']).to be(true)
        end
      end
      context 'with a a custom nick' do
        it 'con join the game with a custom nick' do
          custom_nick = 'my_nick'
          get :join, {game_id: @game.uuid, nick: custom_nick}
          @data = JSON.parse(response.body)
          new_player = Player.find_by(uuid: @data['player_id'])
          expect(new_player.nick).to eq(custom_nick)
        end
      end
    end
    context 'without an unstarted game' do
      after(:each) do
        get :join, {game_id: @game.uuid}
        @data = JSON.parse(response.body)
        expect(@data['registered']).to be(false)
      end
      it 'cannot join an "In Play" game' do
        @game = create(:game, status: 'In Play')
      end
      it 'cannot join a "Completed" game' do
        @game = create(:game, status: 'Completed')
      end
    end
  end

  describe '#start' do
    context 'with an unstarted game' do
      before(:each) do
        @game = create(:game, players_count: 2)
        @creator = @game.creator
        @non_creator = @game.players.last
      end
      context 'as a creator' do
        before(:each) do
          get :start, {game_id: @game.uuid, player_id: @creator.uuid}
          @data = JSON.parse(response.body)
        end
        it 'indicates success' do
          expect(@data['success']).to be(true)
        end
        it 'repsonds with the grid' do
          expect(@data['grid']).to eq(fake_board)
        end
      end
      context 'as a non creator' do
        it 'indicates falure' do
          get :start, {game_id: @game.uuid, player_id: @non_creator.uuid}
          @data = JSON.parse(response.body)
          expect(@data['success']).to be(false)
        end
      end
    end
    context 'without un unstarted game' do
      after(:each) do
        creator = @game.creator
        get :start, {game_id: @game.uuid, player_id: creator.uuid}
        @data = JSON.parse(response.body)
        expect(@data['success']).to be(false)
      end
      it 'cannot join an "In Play" game' do
        @game = create(:game, status: 'In Play')
      end
      it 'cannot join a "Completed" game' do
        @game = create(:game, status: 'Completed')
      end
    end
  end

end
