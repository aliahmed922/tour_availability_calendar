class ToursController < ApplicationController
  # POST /tours
  def create
    @tour = Tour.new(tour_params)

    if @tour.save
      render json: @tour, status: :created, location: @tour
    else
      render json: @tour.errors, status: :unprocessable_entity
    end
  end

  private

    # Only allow a trusted parameter "white list".
    def tour_params
      params.require(:tour).permit(:title,
                                   :start_at,
                                   :end_at,
                                   :full_day,
                                   :recurrence,
                                   :recurring_end_value,
                                   :recurring_interval_value,
                                   :recurring_interval_unit,
                                   :recurring_option_trigger,
                                   :recurring_end_date,
                                   recurring_wdays: [])
    end
end
