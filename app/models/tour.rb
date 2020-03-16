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

  RECURRING_OPTIONS = {
    on_same_day:         'on_same_day',
    every_week_day:      'every_week_day',
    on_current_week_day: 'on_current_week_day'
  }

  # Triggers that will set Specific Week Days / Month Days / Week of the month based on RECURRING_OPTIONS
  RECURRING_OPTION_TRIGGERS = {
    REPEATING_INTERVAL_UNITS[:week].to_sym => {
      RECURRING_OPTIONS[:on_same_day].to_sym => -> (tour ) { tour.change_week_day_to_default! },
      RECURRING_OPTIONS[:every_week_day].to_sym => -> (tour) { tour.recurring_wdays = WEEK_DAYS_RANGE.to_a }
    },
    REPEATING_INTERVAL_UNITS[:month].to_sym => {
      RECURRING_OPTIONS[:on_same_day].to_sym => -> (tour) { tour.set_month_day_to_default! },
      RECURRING_OPTIONS[:on_current_week_day].to_sym => lambda do |tour|
        tour.set_month_day_week!
        tour.change_week_day_to_default!
      end
    }
  }

  # Associations
  #

  # Scopes
  #
  scope :next_tours, -> { where(arel_table[:start_at].gteq(DateTime.now.beginning_of_day)) }

  # Enums
  #
  enum recurrence: RECURRENCE
  enum recurring_interval_unit: REPEATING_INTERVAL_UNITS
  enum recurring_option_trigger: RECURRING_OPTIONS
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
  validate :end_date_is_after_start_date, :limit_recurring_wdays, :valid_trigger_option

  with_options if: :recurring? do
    validates_presence_of :recurring_end_value, :recurring_interval_value, :recurring_interval_unit
    validates_numericality_of :recurring_interval_value, greater_than: 0

    validates_presence_of :recurring_end_date, unless: :never_ending?
  end

  # Callbacks
  #
  before_save :change_hours_to_beginning_and_end_day_hours!, if: :full_day?
  before_save :change_week_day_to_default!, :set_month_day_to_default!, :set_month_day_week!, if: -> record { record.recurring? and record.recurring_option_trigger.nil? }
  before_save :trigger_recurring_option, if: :recurring?

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

  # Performs on before, that sets the week day or month day based on trigger value
  def trigger_recurring_option
    recurring_option_trigger.nil? and return

    RECURRING_OPTION_TRIGGERS[recurring_interval_unit.to_sym][recurring_option_trigger.to_sym].(self)
  end

  # Change week to start_at weekday
  def change_week_day_to_default!
    !weekly? and !monthly? or recurring_wdays.present? and return

    self.recurring_wdays = Array.wrap([start_at.wday])
  end

  # Set month day to start_at month day
  def set_month_day_to_default!
    !monthly? and return

    self.recurring_mday = start_at.mday
  end

  # Set week of month to start_at month week
  def set_month_day_week!
    !monthly? and return

    self.recurring_mday_week = start_at.week_of_month
  end

  protected

  private

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

    def valid_trigger_option
      recurring_option_trigger.nil? and return

      case recurring_interval_unit
        when REPEATING_INTERVAL_UNITS[:week]
          !recurring_option_trigger.to_sym.in?(RECURRING_OPTION_TRIGGERS[:week].keys) and errors.add(:recurring_option_trigger, "Invalid option. Valid options are #{RECURRING_OPTION_TRIGGERS[:week].keys.join(', ')}")
        when REPEATING_INTERVAL_UNITS[:month]
          !recurring_option_trigger.to_sym.in?(RECURRING_OPTION_TRIGGERS[:month].keys) and errors.add(:recurring_option_trigger, "Invalid option. Valid options are #{RECURRING_OPTION_TRIGGERS[:month].keys.join(', ')}")
        else
          nil
      end
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
#  recurring_option_trigger :string
#
