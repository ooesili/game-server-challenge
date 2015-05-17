require 'rails_helper'

fake_board = [
  "SVQNAWRLSCZTVGQ",
  "UJRGVAQAHWQTUSN",
  "DFXOEMTVVBHTIQO",
  "EJOOVNOJMLCRXPI",
  "IEXROADUZIORAMT",
  "NRSHESSVTTMRPRA",
  "BYCAMWXTIHAKUDL",
  "BTCVLFOBUMRTJQU",
  "FZKZOCINEOCOTVM",
  "FYQOPHOTTETAOYM",
  "UXTAOVRNMEWMKTU",
  "AESCSISUIBDDNSN",
  "RJAGTIHKELKTRVX",
  "FPGINTKBMFCXOJP",
  "QCSGBPNAHARAVOA"
].map(&:chars)

fake_inserted_words = [
  "CLINOCLASE",
  "NUMMULATION",
  "PARAMETRITIS",
  "OUTSAVOR",
  "FOOTER",
  "HUMECT",
  "COHIBITOR",
  "VARAHAN",
  "MOUTHROOT",
  "FOREWONTED"
]


RSpec.shared_examples '#play failure' do
  before(:each) do
    @game = create :game, players_count: 2
    @player = @game.current_player
    get :play, {word: @word, game_id: @game.uuid, player_id: @player.uuid}
    @data = JSON.parse(response.body)
  end
  it 'indicates failure' do
    expect(@data['success']).to be(false)
  end
  it 'reports 0 for the score' do
    expect(@data['score']).to be(0)
  end
  it 'does not update the players score' do
    @player.reload
    expect(@player.score).to eq(0)
  end
  it 'does not move to the next player\'s turn' do
    @game.reload
    expect(@game.current_player.id).to eq(@player.id)
  end
  it 'does not marks the word as found' do
    @game.reload
    expect(@game.words_done).not_to include(@word)
  end
end


RSpec.describe GameController, type: :controller do

  before(:each) do
    # create a predictable board
    game_board = GameBoard.new(
      board: fake_board,
      inserted_words: fake_inserted_words
    )
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

  describe '#play' do
    context 'with a valid word' do
      before(:all) do
        @word = fake_inserted_words.sample
      end
      before(:each) do
        # start on the last turn so that we can test the wrap around, as this
        # is the place where things might get go wrong
        players_count = rand(2..10)
        @game = create :game,
          players_count: players_count,
          turn: players_count - 1
        @player = @game.current_player
        get :play, {word: @word, game_id: @game.uuid, player_id: @player.uuid}
        @data = JSON.parse(response.body)
      end
      it 'indicates success' do
        expect(@data['success']).to be(true)
      end
      it 'reports the correct score' do
        expect(@data['score']).to be(@word.size)
      end
      it 'updates the players score' do
        @player.reload
        expect(@player.score).to eq(@data['score'])
      end
      it 'moves to the next player\'s turn' do
        @game.reload
        # as mentioned above, the game was initialized with the turn set to the
        # last player, so we should be on the the first player (AKA the
        # creator) now
        expect(@game.current_player.id).to eq(@game.creator.id)
      end
      it 'marks the word as found' do
        @game.reload
        expect(@game.words_done).to include(@word)
      end
    end
    context 'with a word that is not on the board' do
      before(:all) do
        @word = 'introspection'
      end
      it_behaves_like '#play failure'
    end
    context 'with a non-word that is on the board' do
      before(:all) do
        @word = 'IEXROADUZIO'
      end
      it_behaves_like '#play failure'
    end
    context 'when playing the last word' do
      before(:each) do
        @last_index = rand(fake_inserted_words.size)
        @game = create :game,
          players_count: 2,
          words_done: fake_inserted_words.rotate(@last_index).drop(1),
          status: 'In Play'
        @word = fake_inserted_words[@last_index]
        get :play, {
          word: @word,
          game_id: @game.uuid,
          player_id: @game.current_player.uuid
        }
        @data = JSON.parse(response.body)
      end
      it 'gets a correct score' do
        expect(@data['score']).to eq(@word.size)
      end
      it 'marks the game as completed' do
        @game.reload
        expect(@game.status).to eq('Completed')
      end
    end
  end

  describe '#info' do
    before(:all) do
      @nicks = ['alice', 'bob', 'carol']
    end
    before(:each) do
      @game = create :game, players_count: 0
    end
    context 'with an unplayed game' do
      before(:each) do
        players = @nicks.map do |nick|
          create :player, nick: nick, game: @game
        end
        @player = players.first
        @game.update(creator: @player)
        get :info, {game_id: @game.uuid, player_id: @player.uuid}
        @data = JSON.parse(response.body)
      end
      it 'has the correct status' do
        expect(@data['game_status']).to eq('Waiting')
      end
      it 'has the correct current_player' do
        expect(@data['current_player']).to eq('alice')
      end
      it 'has the correct turn_seq' do
        expect(@data['turn_seq']).to match_array(@nicks)
      end
      it 'has the correct status' do
        scores = @nicks.map{|nick| [nick, 0]}.to_h
        expect(@data['scores']).to eq(scores)
      end
    end
    context 'with an in play game' do
      before(:each) do
        # create the collection of players
        players = @nicks.map do |nick|
          create :player, nick: nick, game: @game, score: rand(0..20)
        end
        @scores = @game.players.pluck(:nick, :score).to_h
        # set creator and turn
        creator = players.first
        @turn = rand players.size
        @game.update(creator: creator, turn: @turn)
        # make the call
        get :info, {game_id: @game.uuid, player_id: creator.uuid}
        @data = JSON.parse(response.body)
        @game.reload
      end
      it 'has the correct status' do
        expect(@data['game_status']).to eq('Waiting')
      end
      it 'has the correct current_player' do
        expect(@data['current_player']).to eq(@game.current_player.nick)
      end
      it 'has the correct turn_seq' do
        expect(@data['turn_seq']).to match_array(@nicks.rotate(@turn))
      end
      it 'has the correct status' do
        expect(@data['scores']).to eq(@scores)
      end
    end
  end

end
