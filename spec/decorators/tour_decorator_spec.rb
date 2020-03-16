require 'rails_helper'

RSpec.describe TourDecorator, type: :decorator do
  subject { FactoryBot.build(:tour).decorate }

  context '#week_days_by_name' do
    it 'returns a hash' do
      expect(subject.week_days_by_name).to be_kind_of(Hash)
    end

    it 'gives a week number by name of week in a symbol' do
      days      = %i[sunday monday tuesday wednesday thursday friday saturday]
      week_days = subject.week_days_by_name.keys
      expect(week_days.index(:sunday)).to eq(days.index(:sunday))
    end
  end
end