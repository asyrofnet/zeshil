source 'https://rubygems.org'

# User stable release of ruby 2.4.0 for this project
ruby '2.4.1'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.0', '>= 5.1.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.18'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.3', '>= 3.3.3'
# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
# Rack Cors gem is to handle cors issue in browsers
gem 'rack-cors'

# JSON WEB TOKEN
gem 'jwt'

# This Gem adds useful methods to your Rails app to validate, display and save phone numbers. It uses the super awesome Phony gem (https://github.com/floere/phony).
gem 'phony'
gem 'phony_rails' # Include phony_rails after mongoid (if you use mongoid, see issue #66 on github).

# SDK for nexmo sms handling
gem 'nexmo'
# SDK for twilio sms handling
gem 'twilio-ruby', '~> 5.5.0'

# Cloudinary file hosting
gem 'cloudinary'

# ⚡ A Scope & Engine based, clean, powerful, customizable and sophisticated paginator for Ruby webapps
gem 'kaminari'

# Removes invalid UTF-8 characters from the environment so that your app doesn't choke on them. This prevents errors like "invalid byte sequence in UTF-8"
gem 'utf8-cleaner'

#mailgun
gem 'mailgun-ruby', '~>1.1.2'

# add faker to dummy data
gem 'faker'

# Versionomy is a generalized version number library. It provides tools to represent, manipulate, parse, and compare version numbers in the wide variety of versioning schemes in use.
gem 'versionomy'

# Sentry raven for logging
gem 'sentry-raven'

gem 'twitter-bootstrap-rails', '~> 3.2', '>= 3.2.2'

# Complete Ruby geocoding solution. https://github.com/alexreisner/geocoder
gem 'geocoder'

gem 'sidekiq'

# https://github.com/minad/mimemagic
# MimeMagic is a library to detect the mime type of a file by extension or by content. It uses the mime database provided by freedesktop.org (see http://freedesktop.org/wiki/Software/shared-mime-info/).
gem 'mimemagic', '0.3.0'

# New Relic RPM Ruby Agent http://www.newrelic.com
gem 'newrelic_rpm'

# https://github.com/taf2/curb
# http://reevoo.github.io/blog/2014/09/12/http-shooting-party/
# => If raw performance is important use curb or if you want to use faraday then go for patron
gem 'curb'

# Simple, but flexible HTTP client library, with support for multiple backends.
gem 'faraday'

gem 'em-http-request'

# Apple Push Notifications
gem 'apnotic'

# Android Push Notifications
gem 'fcm'

# Multipart POST capability to net/http
gem 'multipart-post'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  # Simple, Heroku-friendly Rails app configuration using ENV and a single YAML file
  gem "figaro"

  # Pin minitest to the previous version
  gem 'minitest', '5.10.1'

  # help to kill N+1 queries and unused eager loading
  gem 'bullet'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # help to kill N+1 queries and unused eager loading
  gem 'bullet'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]


# Test settings
group :test do
  # Mocha is mocking library that works well with minitest
  gem 'mocha'
  #Gem to check test coverage
  gem 'simplecov', require: false

  # help to kill N+1 queries and unused eager loading
  gem 'bullet'
end
