FactoryGirl.define do
  factory :player do
    sequence(:nick) {|n| "player#{n}"}
  end
end
