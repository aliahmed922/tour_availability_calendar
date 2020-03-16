FactoryBot.define do
  factory :tour do
    title { 'Adventour' }
    start_at { DateTime.new(2020, 02, 20) }
    end_at { start_at + 2.days }

    factory :one_time_tour_with_dates do
      transient do
        dates { [] }
      end


    end
  end
end