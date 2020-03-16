class AddRecurringOptionTriggerToTours < ActiveRecord::Migration[6.0]
  def change
    add_column :tours, :recurring_option_trigger, :string
  end
end
