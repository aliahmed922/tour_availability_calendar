FactoryBot.define do
  factory :tour do
    title { 'Adventour' }
    start_at { DateTime.new(2020, 02, 20) }
    end_at { start_at + 2.days }
  end
end