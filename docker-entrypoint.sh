#!/bin/bash
set -e

echo "Starting Rails application..."

# Wait for database to be ready
echo "Waiting for database..."
until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" >/dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 1
done

echo "Database is up!"

# Create and migrate database
echo "Setting up database..."
bundle exec rails db:create || echo "Database already exists"
bundle exec rails db:migrate

# Start the Rails server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0