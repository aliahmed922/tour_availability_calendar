class Tour < ApplicationRecord
  # Concerns Macros
  #

  # Constants
  #
  WEEK_DAYS_RANGE = (0..6)

  RECURRENCE = {
    once:      'once',
    recurring: 'recurring'
  }

  END_OPTIONS = {
    never: 'never',
    on:    'on'
  }.freeze

  REPEATING_INTERVAL_UNITS = {
    day:   'day',
    month: 'month',
    week:  'week',
    year:  'year'
  }.freeze

  # Associations
  #

  # Scopes
  #

  # Enums
  #
  enum recurrence: RECURRENCE
  enum recurring_interval_unit: REPEATING_INTERVAL_UNITS
  alias_method :daily?, :day?
  alias_method :weekly?, :week?
  alias_method :monthly?, :month?
  alias_method :yearly?, :year?

  # Delegates
  #

  # Macros
  #

  # Validations
  #
  validates_presence_of :title, :start_at, :recurrence
  validate :end_date_is_after_start_date, :limit_recurring_wdays

  with_options if: :recurring? do
    validates_presence_of :recurring_end_value, :recurring_interval_value, :recurring_interval_unit
    validates_numericality_of :recurring_interval_value, greater_than: 0

    validates_presence_of :recurring_end_date, unless: :never_ending?
  end

  # Callbacks
  #
  before_save :change_hours_to_beginning_and_end_day_hours!, if: :full_day?
  before_save :change_week_day_to_default!, :chang_month_day_to_default!, :set_month_day_week!, if: :recurring?

  # Class Methods
  #

  # Instance Methods
  #
  def never_ending?
    recurring? and recurring_end_value == END_OPTIONS[:never]
  end

  def decorate
    @decorate ||= TourDecorator.new(self)
  end

  def recurring_wdays=(value)
    super(value&.sort&.uniq)
  end

  protected

  private

    def change_week_day_to_default!
      !weekly? or recurring_wdays.present? and return

      self.recurring_wdays = Array.wrap([start_at.wday])
    end

    def chang_month_day_to_default!
      !monthly? or recurring_mday.present? and return

      self.recurring_mday = start_at.mday
    end

    def set_month_day_week!
      !monthly? and return

      self.recurring_mday_week = start_at.week_of_month
    end

    def change_hours_to_beginning_and_end_day_hours!
      start_at.blank? or end_at.blank? and return

      self.start_at = self.start_at.beginning_of_day
      self.end_at   = self.end_at.end_of_day
    end

    def end_date_is_after_start_date
      start_at.blank? or end_at.blank? and return

      end_at < start_at and errors.add(:end_date, 'cannot be before the start date')
    end

    def limit_recurring_wdays
      recurring_wdays.nil? and return

      !recurring_wdays.all? { |element| WEEK_DAYS_RANGE.cover?(element&.to_i) } and errors.add(:recurring_wdays, 'values must be in 0..6 range')
    end
end

# == Schema Information
#
# Table name: tours
#
#  id                       :bigint(8)        not null, primary key
#  title                    :string
#  start_at                 :datetime
#  end_at                   :datetime
#  full_day                 :boolean          default(FALSE)
#  recurrence               :string           not null, default("once")
#  recurring_end_value      :string           not null, default("never")
#  recurring_interval_value :integer          default(0)
#  recurring_interval_unit  :string
#  recurring_wdays          :text             array, default([])
#  recurring_mday           :integer
#  recurring_mday_week      :integer
#  recurring_end_date       :date
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
