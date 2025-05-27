source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.0'

gem 'rails', '~> 8.0.0'
gem 'pg', '~> 1.1'
gem 'puma', '~> 6.0'
gem 'grpc', '~> 1.59'
gem 'grpc-tools', '~> 1.59'
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.0'
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'spring'
end