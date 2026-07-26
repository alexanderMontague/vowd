source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.0"

gem "bcrypt", "~> 3.1.7"
gem "bootsnap", require: false
gem "dotenv-rails"
gem "rqrcode"
gem "aws-sdk-s3"
gem "image_processing", "~> 1.13"
gem "importmap-rails"
gem "jbuilder"
gem "propshaft"
gem "puma", "~> 6.0"
gem "rails", "~> 7.1.0"
gem "ruby-vips", "~> 2.2"
gem "sqlite3", "~> 2.0.2"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

group :development, :test do
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "faker"
  # Rails 7.1's test runner is incompatible with minitest 6's changed `run`
  # signature; keep it on the 5.x series until Rails catches up.
  gem "minitest", "~> 5.0"
end

group :development do
  gem "foreman"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem "dockerfile-rails", ">= 1.7", :group => :development
