require 'rails_helper'
RSpec.describe ToursController, type: :request do
  context 'Create Tour' do
    subject(:tour) { FactoryBot.build(:tour) }

    context 'One Time' do
      let(:params) {
        {
          tour: {
            title: tour.title,
            start_at: tour.start_at,
            end_at: tour.end_at,
            recurrence: tour.recurrence
          }
        }
      }
      it 'creates a tour with start and end date at default hours' do
        post '/tours', params: params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['title']).to eq(tour.title)
      end

      it 'creates a custom day tour' do
        start_time = DateTime.strptime('2020-02-20T06:30 AM', '%Y-%m-%dT%I:%M %p')
        end_time   = DateTime.strptime('2020-02-20T09:30 PM', '%Y-%m-%dT%I:%M %p')
        params[:tour].merge!(full_day: false, start_at: start_time, end_at: end_time)
        post '/tours', params: params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['start_at'].to_datetime).to eq(start_time)
        expect(JSON.parse(response.body)['end_at'].to_datetime).to eq(end_time)
      end

      it 'creates a full day tour' do
        start_time = DateTime.strptime('2020-02-20T06:30 AM', '%Y-%m-%dT%I:%M %p')
        end_time   = DateTime.strptime('2020-02-20T09:30 PM', '%Y-%m-%dT%I:%M %p')
        params[:tour].merge!(full_day: true, start_at: start_time, end_at: end_time)
        post '/tours', params: params
        expect(response).to have_http_status(:success)
        expected_start_time = DateTime.strptime('2020-02-20T12:00 AM', '%Y-%m-%dT%I:%M %p')
        expected_end_time   = DateTime.strptime('2020-02-20T11:59:59:999000000 PM', '%Y-%m-%dT%I:%M:%S:%L %p')
        expect(JSON.parse(response.body)['start_at'].to_datetime).to eq(expected_start_time)
        expect(JSON.parse(response.body)['end_at'].to_datetime).to eq(expected_end_time)
      end

      it 'cannot create a tour without required attributes' do
        post '/tours', params: { tour: { title: nil, start_at: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates a tour on Jan 5th' do
        start_time = DateTime.strptime('2020-01-05', '%Y-%m-%d')
        end_time   = start_time + 2.days
        params[:tour].merge!(start_at: start_time, end_at: end_time)
        post '/tours', params: params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['start_at'].to_datetime).to eq(start_time)
        expect(JSON.parse(response.body)['end_at'].to_datetime).to eq(end_time)
      end
    end

    context 'Recurring' do
      subject(:tour) { FactoryBot.build(:tour, recurrence: Tour::RECURRENCE[:recurring]) }
      let(:params) {
        {
          tour: {
            title: tour.title,
            start_at: tour.start_at,
            end_at: tour.end_at,
            recurrence: tour.recurrence,
            recurring_end_value: Tour::END_OPTIONS[:never],
            recurring_interval_value: 1,
            recurring_interval_unit: Tour::REPEATING_INTERVAL_UNITS[:day]
          }
        }
      }

      it 'creates a Daily recurring Tour' do
        post '/tours', params: params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['recurrence']).to eq(Tour::RECURRENCE[:recurring])
        expect(JSON.parse(response.body)['recurring_end_value']).to eq(Tour::END_OPTIONS[:never])
        expect(JSON.parse(response.body)['recurring_interval_value']).to eq('1')
        expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:day])
      end

      it 'creates a Daily recurring Tour' do
        post '/tours', params: params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['recurrence']).to eq(Tour::RECURRENCE[:recurring])
        expect(JSON.parse(response.body)['recurring_end_value']).to eq(Tour::END_OPTIONS[:never])
        expect(JSON.parse(response.body)['recurring_interval_value']).to eq('1')
        expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:day])
      end

      context 'Weekly Tour' do
        before do
          params[:tour].merge!(recurring_interval_unit: Tour::REPEATING_INTERVAL_UNITS[:week])
        end

        it 'creates a weekly: Every Monday' do
          params[:tour].merge!(
            recurring_wdays: [
                               week_days_by_name(tour, :monday)
                             ].map(&:to_s)
          )
          post '/tours', params: params
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['recurring_wdays']).to match_array([week_days_by_name(tour, :monday).to_s])
          expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:week])
        end

        it 'creates a weekly tour: Every Tuesday and Thursday' do
          params[:tour].merge!(
            recurring_wdays: [
                               tour.decorate.week_days_by_name[:tuesday],
                               tour.decorate.week_days_by_name[:thursday],
                             ].map(&:to_s)
          )

          post '/tours', params: params
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['recurring_wdays']).to match_array([week_days_by_name(tour, :tuesday).to_s, week_days_by_name(tour, :thursday).to_s])
          expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:week])
        end
      end

      context 'Monthly Tour' do
        before do
          params[:tour].merge!(recurring_interval_unit: Tour::REPEATING_INTERVAL_UNITS[:month])
        end

        it 'creates a monthly tour: Every same date of start date' do
          params[:tour].merge!(recurring_option_trigger: Tour::RECURRING_OPTIONS[:on_same_day])
          post '/tours', params: params
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['recurring_wdays']).to be_empty
          expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:month])
          expect(JSON.parse(response.body)['recurring_mday']).to eq(tour.start_at.mday)
        end

        it 'creates a monthly tour: Every same week and same day' do
          params[:tour].merge!(recurring_option_trigger: Tour::RECURRING_OPTIONS[:on_current_week_day])
          post '/tours', params: params
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:month])
          expect(JSON.parse(response.body)['recurring_wdays']).to match_array([tour.start_at.wday.to_s])
          expect(JSON.parse(response.body)['recurring_mday']).to be_nil
          expect(JSON.parse(response.body)['recurring_mday_week']).to eq(tour.start_at.week_of_month)
        end

        it 'creates a monthly tour: Every second tuesday of month' do
          start_time = DateTime.strptime('2020-02-04', '%Y-%m-%d')
          end_time   = DateTime.strptime('2020-02-04', '%Y-%m-%d')
          params[:tour].merge!(
            start_at: start_time,
            end_at: end_time,
            recurring_option_trigger: Tour::RECURRING_OPTIONS[:on_current_week_day]
          )
          post '/tours', params: params
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['recurring_interval_unit']).to eq(Tour::REPEATING_INTERVAL_UNITS[:month])
          expect(JSON.parse(response.body)['recurring_wdays']).to match_array([week_days_by_name(tour, :tuesday).to_s])
          expect(JSON.parse(response.body)['recurring_mday']).to be_nil
          expect(JSON.parse(response.body)['recurring_mday_week']).to eq(2)
        end
      end

      context 'Recurring End Date Tour' do
        it 'creates a tour that can end on specified date' do
          end_date = Date.strptime('2020-05-04', '%Y-%m-%d')
          params[:tour].merge!(recurring_end_date: end_date)
          post '/tours', params: params
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)['recurring_end_date'].to_date).to eq(end_date)
        end
      end

      def week_days_by_name(tour, name)
        tour.decorate.week_days_by_name[name]
      end
    end
  end
end