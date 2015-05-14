FactoryGirl.define do
  factory :game do
    # allow callers to change the number of players
    transient do
      players_count 1
    end
    # use the existing factory
    initialize_with { Game.build(15, 10) }
    # create players and set the creator
    after(:create) do |game, evaluator|
      players = create_list(:player, evaluator.players_count, game: game)
      game.update(creator: players.first) if players.size > 0
    end
  end
end
