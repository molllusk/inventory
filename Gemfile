ruby '2.5.3'
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


gem 'airbrake', '~> 7.4'
gem 'annotate'
gem 'bcrypt',         '3.1.12'
gem 'bootstrap-sass', '3.4.1'
gem 'bootstrap-will_paginate', '1.0.0'
gem 'coffee-rails', '~> 4.2'
gem 'faraday'
gem 'faraday_middleware'
gem 'filterrific'
gem 'font-awesome-sass'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails', '4.3.1'
gem 'pg', '0.20.0'
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.2.2'
gem 'rails_12factor'
gem 'sass-rails', '~> 5.0'
gem 'sendgrid-ruby'
gem 'turbolinks', '~> 5'
gem 'uglifier', '>= 1.3.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'dotenv-rails'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  # gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
