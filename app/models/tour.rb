class Tour < ApplicationRecord
  # Concerns Macros
  #

  # Constants
  #
  RECURRENCE = {
    once:       'once',
    recurrence: 'recurrence'
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
  enum repeating: REPEATING_INTERVAL_UNITS

  # Delegates
  #

  # Macros
  #

  # Validations
  #

  # Callbacks
  #

  # Class Methods
  #

  # Instance Methods
  #

  protected

  private
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
#  recurring_wday           :integer
#  recurring_wday           :integer
#  recurring_mday           :integer
#  recurring_mday_week      :integer
#  recurring_end_date       :date
#  updated_at               :datetime         not null
#
