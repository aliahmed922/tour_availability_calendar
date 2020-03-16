require 'rails_helper'

RSpec.describe Tour, type: :model do
  let(:start_at) { DateTime.new(2020, 02, 20) }
  subject { FactoryBot.build(:tour) }

  describe 'Enums' do
    it do
      should define_enum_for(:recurrence).
        with_values(described_class::RECURRENCE).
        backed_by_column_of_type(:string)
    end

    it do
      should define_enum_for(:recurring_interval_unit).
        with_values(described_class::REPEATING_INTERVAL_UNITS).
        backed_by_column_of_type(:string)
    end

    it do
      should define_enum_for(:recurring_option_trigger).
        with_values(described_class::RECURRING_OPTIONS).
        backed_by_column_of_type(:string)
    end
  end

  describe 'Validations' do
    before do
      subject.assign_attributes(recurrence: described_class::RECURRENCE[:once])
    end

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "is not valid without a title" do
      subject.title = nil
      expect(subject).to_not be_valid
    end

    it "is not valid without a start_at" do
      subject.start_at = nil
      expect(subject).to_not be_valid
    end

    it "is not valid without a recurrence" do
      subject.recurrence = nil
      expect(subject).to_not be_valid
    end

    it 'is not valid when end at is after start at' do
      subject.end_at = subject.start_at - 1.day
      expect(subject).to_not be_valid
    end

    it 'is not valid when end at hours is after start at hours' do
      subject.start_at = subject.start_at.change(hour: 8)
      subject.end_at   = subject.start_at.change(hour: 5)
      expect(subject).to_not be_valid
    end

    it 'is valid when end at is after or equal to start at' do
      subject.end_at = subject.start_at
      expect(subject).to be_valid
    end

    context 'Recurring' do
      before do
        subject.assign_attributes(recurrence: described_class::RECURRENCE[:recurring],
                                  recurring_end_value: described_class::END_OPTIONS[:never],
                                  recurring_interval_value: 1,
                                  recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:day])
      end

      it 'is valid with valid attributes' do
        expect(subject).to be_valid
      end

      it 'is not valid without recurring_end_value' do
        subject.recurring_end_value = nil
        expect(subject).to_not be_valid
      end

      it 'is not valid when recurring_end_value is less than 1' do
        subject.recurring_end_value = 0
        expect(subject).to_not be_valid
      end

      it 'is not valid when recurring_wdays do not match weekday range' do
        subject.recurring_wdays = [8, 3]
        expect(subject).to_not be_valid
      end

      it 'is valid when recurring_wdays not match weekday range' do
        subject.recurring_wdays = [subject.decorate.week_days_by_name[:monday], subject.decorate.week_days_by_name[:saturday]]
        expect(subject).to be_valid
      end

      it 'is not valid without recurring_interval_value' do
        subject.recurring_interval_value = nil
        expect(subject).to_not be_valid
      end

      it 'is not valid without recurring_interval_unit' do
        subject.recurring_interval_unit = nil
        expect(subject).to_not be_valid
      end


      it 'is not valid without recurring_end_date when recurring can be ended' do
        subject.recurring_end_value = described_class::END_OPTIONS[:on]
        subject.recurring_end_date  = nil
        expect(subject).to_not be_valid
      end

      it 'is valid with recurring_end_date when recurring can be ended' do
        subject.recurring_end_value = described_class::END_OPTIONS[:on]
        subject.recurring_end_date  = subject.end_at
        expect(subject).to be_valid
      end

      it 'is not valid with invalid recurring_option_trigger value when interval is weekly' do
        subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:week]
        subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:on_current_week_day]
        expect(subject).to_not be_valid
      end

      it 'is not valid with invalid recurring_option_trigger value when interval is monthly' do
        subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:monthly]
        subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:every_week_day]
        expect(subject).to_not be_valid
      end

      it 'is valid with valid recurring_option_trigger value when interval is weekly' do
        subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:week]
        subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:every_week_day]
        expect(subject).to be_valid
      end

      it 'is valid with valid recurring_option_trigger value when interval is monthly' do
        subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:month]
        subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:on_current_week_day]
        expect(subject).to be_valid
      end
    end
  end

  describe 'Callbacks' do
    context 'Before Save' do
      context 'One Time' do
        context '#change_hours_to_beginning_and_end_day_hours!' do
          before do
            subject.start_at = DateTime.strptime('2020-02-20T06:30 AM', '%Y-%m-%dT%I:%M %p')
            subject.end_at   = DateTime.strptime('2020-02-20T09:30 PM', '%Y-%m-%dT%I:%M %p')
          end

          it 'changes start and end at hours to initial hours when tour is full day' do
            subject.full_day = true
            subject.save
            expect(subject.start_at.strftime('%I:%M %p')).to eq('12:00 AM')
            expect(subject.end_at.strftime('%I:%M %p')).to eq('11:59 PM')
          end

          it 'does not change start and end at hours to initial hours when tour is not full day' do
            subject.save
            expect(subject.start_at.strftime('%I:%M %p')).to eq('06:30 AM')
            expect(subject.end_at.strftime('%I:%M %p')).to eq('09:30 PM')
          end
        end
      end

      context 'Recurring' do
        before do
          subject.assign_attributes(recurrence: described_class::RECURRENCE[:recurring],
                                    recurring_end_value: described_class::END_OPTIONS[:never],
                                    recurring_interval_value: 1)

        end

        context '#trigger_recurring_option' do
          context 'Weekly' do
            before { subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:week] }

            it 'changes week days to same day, extract from start date day' do
              subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:on_same_day]
              subject.save
              expect(subject.recurring_wdays).to match_array([subject.start_at.wday].map(&:to_s))
            end

            it 'changes week days to every week day' do
              subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:every_week_day]
              subject.save
              expect(subject.recurring_wdays).to match_array(described_class::WEEK_DAYS_RANGE.to_a.map(&:to_s))
            end
          end

          context 'Monthly' do
            before { subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:month] }

            it 'changes month day to same day of the month, extract from start date day' do
              subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:on_same_day]
              subject.save
              expect(subject.recurring_mday).to eq(subject.start_at.mday)
            end

            it 'changes week day and week of month, extract from start date' do
              subject.recurring_option_trigger = described_class::RECURRING_OPTIONS[:on_current_week_day]
              subject.save
              expect(subject.recurring_wdays).to match_array([subject.start_at.wday.to_s])
              expect(subject.recurring_mday_week).to eq(subject.start_at.week_of_month)
            end
          end
        end

        context '#change_week_day_to_default!' do
          before { subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:week] }

          it 'changes week days to default, extract from start date day, when week days are not assigned' do
            subject.recurring_wdays.clear
            subject.save
            expect(subject.recurring_wdays).to match_array([subject.start_at.wday].map(&:to_s))
          end

          it 'does not change week day to default when week days are assigned' do
            days = Array.wrap([subject.decorate.week_days_by_name[:monday], subject.decorate.week_days_by_name[:wednesday]])
            subject.recurring_wdays = days
            subject.save
            expect(subject.recurring_wdays).to match_array(days.map(&:to_s))
          end
        end

        context '#change_to_default_month_day' do
          before { subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:month] }

          it 'changes month day, extract from start date day, when interval is monthly' do
            subject.save
            expect(subject.recurring_mday).to eq(subject.start_at.mday)
          end
        end

        context '#set_month_day_week!' do
          before { subject.recurring_interval_unit = described_class::REPEATING_INTERVAL_UNITS[:month] }

          it 'sets month day week, extract from start date day, when interval is monthly' do
            subject.save
            expect(subject.recurring_mday_week).to eq(subject.start_at.week_of_month)
          end
        end
      end
    end
  end

  describe 'Scopes' do
    context '.next_tours' do
      it 'gets next upcoming tours' do
        FactoryBot.create(:tour)

        FactoryBot.create(:tour, start_at: DateTime.now.beginning_of_day)
        FactoryBot.create(:tour, start_at: DateTime.now.beginning_of_day + 2.days)
        FactoryBot.create(:tour, start_at: DateTime.now.beginning_of_day + 5.days)

        expect(described_class.next_tours.count).to eq(3)
      end
    end
  end

  describe 'Instance Methods' do
    context '#never_ending?' do
      before do
        subject.assign_attributes(
          recurrence: described_class::RECURRENCE[:recurring],
          recurring_interval_value: 1,
          recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:day]
        )
      end

      it 'returns TRUE whem tour can never be ended' do
        subject.recurring_end_value = described_class::END_OPTIONS[:never]
        expect(subject.never_ending?).to be_truthy
      end

      it 'returns FALSE when tour can be ended' do
        subject.recurring_end_value = described_class::END_OPTIONS[:on]
        subject.recurring_end_date  = subject.end_at
        expect(subject.never_ending?).to be_falsey
      end
    end

    context '#decorate' do
      it 'becomes a decorated object' do
        expect(subject.decorate).to be_kind_of(TourDecorator)
      end
    end

    context '#recurring_wdays=' do
      it 'makes a sorted and uniq array value' do
        subject.assign_attributes(
          recurrence: described_class::RECURRENCE[:recurring],
          recurring_interval_value: 1,
          recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:week],
          recurring_wdays: [3, 2, 0, 0]
        )

        expect(subject.recurring_wdays).to match_array([0, 2, 3].map(&:to_s))
      end
    end

    context '#trigger_recurring_option' do
      before do
        subject.assign_attributes(recurrence: described_class::RECURRENCE[:recurring], recurring_interval_value: 1)
      end

      it 'triggers recurring option as same day of week' do
        subject.assign_attributes(
          recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:week],
          recurring_option_trigger: described_class::RECURRING_OPTIONS[:on_same_day]
        )

        subject.trigger_recurring_option
        expect(subject.recurring_wdays).to match_array([subject.start_at.wday].map(&:to_s))
      end

      it 'triggers recurring option as every day of week' do
        subject.assign_attributes(
          recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:week],
          recurring_option_trigger: described_class::RECURRING_OPTIONS[:every_week_day]
        )
        subject.trigger_recurring_option
        expect(subject.recurring_wdays).to match_array(described_class::WEEK_DAYS_RANGE.to_a.map(&:to_s))
      end

      it 'triggers recurring option as same day of every month' do
        subject.assign_attributes(
          recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:month],
          recurring_option_trigger: described_class::RECURRING_OPTIONS[:on_same_day]
        )
        subject.trigger_recurring_option
        expect(subject.recurring_mday).to eq(subject.start_at.mday)
      end

      it 'triggers recurring option as same day and same week every month' do
        subject.assign_attributes(
          recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:month],
          recurring_option_trigger: described_class::RECURRING_OPTIONS[:on_current_week_day]
        )
        subject.trigger_recurring_option
        expect(subject.recurring_wdays).to match_array([subject.start_at.wday].map(&:to_s))
        expect(subject.recurring_mday_week).to eq(subject.start_at.week_of_month)
      end
    end

    context '#change_week_day_to_default!' do
      before do
        subject.assign_attributes(recurrence: described_class::RECURRENCE[:recurring], recurring_interval_value: 1)
      end

      it 'changes #recurring_wdays to default when interval is week' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:week])
        subject.change_week_day_to_default!
        expect(subject.recurring_wdays).to match_array([subject.start_at.wday].map(&:to_s))
      end

      it 'changes #recurring_wdays to default when interval is monthly' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:month])
        subject.change_week_day_to_default!
        expect(subject.recurring_wdays).to match_array([subject.start_at.wday].map(&:to_s))
      end

      it 'does nothing when interval is not weekly or monthly' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:day])
        expect(subject.change_week_day_to_default!).to be_nil
        expect(subject.recurring_wdays).to be_empty
      end

      it 'does nothing when #recurring_wdays is present' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:week])
        subject.recurring_wdays = [subject.decorate.week_days_by_name[:monday]]
        expect(subject.change_week_day_to_default!).to be_nil
        expect(subject.recurring_wdays).to match_array([subject.decorate.week_days_by_name[:monday].to_s])
      end
    end

    context '#chang_month_day_to_default!!' do
      before do
        subject.assign_attributes(recurrence: described_class::RECURRENCE[:recurring], recurring_interval_value: 1)
      end

      it 'changes #recurring_mday to default when interval is monthly' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:month])
        subject.chang_month_day_to_default!
        expect(subject.recurring_mday).to eq(subject.start_at.mday)
      end

      it 'does nothing when interval is not monthly' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:day])
        expect(subject.chang_month_day_to_default!).to be_nil
        expect(subject.recurring_mday).to be_nil
      end
    end

    context '#set_month_day_week!!!' do
      before do
        subject.assign_attributes(recurrence: described_class::RECURRENCE[:recurring], recurring_interval_value: 1)
      end

      it 'changes #recurring_mday_week to default when interval is monthly' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:month])
        subject.set_month_day_week!
        expect(subject.recurring_mday_week).to eq(subject.start_at.week_of_month)
      end

      it 'does nothing when interval is not monthly' do
        subject.assign_attributes(recurring_interval_unit: described_class::REPEATING_INTERVAL_UNITS[:day])
        expect(subject.set_month_day_week!).to be_nil
        expect(subject.recurring_mday_week).to be_nil
      end
    end
  end
end
