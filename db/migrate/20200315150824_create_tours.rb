class CreateTours < ActiveRecord::Migration[6.0]
  def change
    create_table :tours do |t|
      t.string :title
      t.datetime :start_at
      t.datetime :end_at
      # Full Day tour will determine that whether a start/ end date can have specific hours or not.
      t.boolean :full_day, default: false
      # Tour recurrence can be One Time or Repeating
      t.string :recurrence, null: false, default: Tour::RECURRENCE[:once]
      # By default, repeating tour will never end.
      t.string :recurring_end_value, null: false, default: Tour::END_OPTIONS[:never]
      # Interval value of recurring tour. E.g Every 1 / Every 2
      t.string :recurring_interval_value, default: 0
      # Interval unit of recurring tour. E.g Day, Week
      t.string :recurring_interval_unit
      # Number of the week days (1 -> Monday, 2 -> Tuesday etc) in a given week when recurring_interval_unit is Week
      # E.g If given, Every 1 Week, then default day would be extracted from the selected start_date value i.e (if start date is Feb 20, 2020 then day would be 4 -> Thursday)
      t.text :recurring_wdays, array: true, default: []
      # Number of days in a given month when recurring_interval_unit is Month
      # E.g If given, Every 1 Month, then default day would be extracted from the selected start date value i.e (if start date is Feb 20, 2020 then day would be 20)
      t.integer :recurring_mday
      # Week number of the month from start date E.g (if start date is Feb 20, 2020 then the week number would be 4)
      t.integer :recurring_mday_week
      # Date on which the recurring event will be cancelled
      t.date :recurring_end_date

      t.timestamps
    end
  end
end
