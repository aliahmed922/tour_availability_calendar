class TourDecorator < SimpleDelegator
  # Returns a hash of Week Days
  # => {:sunday=>0, :monday=>1, :tuesday=>2, :wednesday=>3, :thursday=>4, :friday=>5, :saturday=>6}
  def week_days_by_name
    @week_days_by_name ||= %i[sunday monday tuesday wednesday thursday friday saturday].map.with_index { |wday, index| [wday, index]  }.to_h
  end
end