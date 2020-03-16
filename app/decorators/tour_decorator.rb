class TourDecorator < SimpleDelegator
  def week_day_by_name
    %i[sunday monday tuesday wednesday thursday friday saturday].map.with_index { |wday, index| [wday, index]  }.to_h
  end
end