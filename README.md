# Simple Tour Availability Calendar

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
