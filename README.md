# Simple Tour Availability Calendar
This is a Simple API Rails app that creates a Tour availability calendar.

## Requirements

* Ruby 2.6.3
* Rails 6.0.0
* PostgreSQL

### App Installation

Once Rails/Ruby installed, app can be configured by following below steps:

1. Clone the repo `git clone https://github.com/aliahmed922/tour_availability_calendar.git`
2. `cd` to 'tour_availability_calendar.git'
3. Run `bundle`
4. Configure Postgres Env Vars `export POSTGRES_USERNAME=<your postgres username>` and `export POSTGRES_PASSWORD=<your postgres password>`
5. Run `rails db:create db:migrate`
6. Run test cases `rspec`

### How to Use
It has a single endpoint that creates a Tour record. There are following options that can be passed to create different types of Tour.

POST - Create Tour
---
`http://localhost:3000/tours`

**Request Params**:

| Parameters | Type | Required | Value | Description
|------------|--------|----------|:-------:|---------|
| title                    | String   | True  | ---                        | Title of the Tour (e.g Adventor) |
| start_at                 | DateTime | True  | ---                        | DateTime in format (YYYY-MM-DD HH:MM:SS) |
| end_at                   | DateTime | True  | ---                        | DateTime in format (YYYY-MM-DD HH:MM:SS)
| full_day                 | Boolean  | False | ---                        | Default is False, When set to true, the start_at and end_at becomes date instead of datetime. |
| recurrence               | String   | True  | once / recurring           | `once` Makes a tour One Time which will end on specified end_at date. `recurring` Makes a repeating tour based on repeating value and repeating interval unit and can be ended based on `recurring_end_value` and `recurring_end_date`.
| recurring_end_value      | String   | True  | never / on                 | `never` will never end the recurring tour. `on` will require `recurring_end_date` which will end the tour on this date.
| recurring_interval_value | Integer  | True  | ---                        | Number of interval E.g 1 or 2
| recurring_interval_unit  | String   | True                               | --- | day / week / month / year | Recurring interval unit
| recurring_option_trigger | String   | False                              | --- | on_same_day / every_week / on_current_week_day | `on_same_day` will only work when `recurring_interval_unit` value is either `week` or `month`. This will repeat the tour on same day of the `start_at` date. `every_week_day` will work only when `recurring_interval_unit` value is  `week`. This will repeat on every day of the week. `on_current_week_day` will only work when `recurring_interval_unit` value is `month`. This will repeat tour on same week, same day of the repeating month (E.g Every second Thursday of the month).
| recurring_end_date       | Date     | False. True only if 
                                        `recurring_interval_value` is `on` | --- | Date in format (YYYY-MM-DD).
| recurring_wdays          | Array    | False | Range 0 to 6               | Values from 0..6. These values represent the week days as 0 = Sunday, 1 = Monday etc


