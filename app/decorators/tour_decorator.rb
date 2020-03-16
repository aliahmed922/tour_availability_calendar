class TourDecorator < SimpleDelegator
  def week_days_by_name
    %i[sunday monday tuesday wednesday thursday friday saturday].map.with_index { |wday, index| [wday, index]  }.to_h
  end
end