#!/bin/bash
set -e

echo "Starting Rails application..."

# Wait for database to be ready with timeout
echo "Waiting for database..."
DB_WAIT_TIMEOUT=60
DB_WAIT_COUNT=0

until bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" >/dev/null 2>&1; do
  echo "Database is unavailable - sleeping (${DB_WAIT_COUNT}/${DB_WAIT_TIMEOUT}s)"
  sleep 1
  DB_WAIT_COUNT=$((DB_WAIT_COUNT + 1))
  
  if [ $DB_WAIT_COUNT -ge $DB_WAIT_TIMEOUT ]; then
    echo "ERROR: Database did not become available within ${DB_WAIT_TIMEOUT} seconds"
    echo "Check database configuration and connection settings"
    exit 1
  fi
done

echo "Database is up!"

# Create and migrate database
echo "Setting up database..."
bundle exec rails db:create || echo "Database already exists"
bundle exec rails db:migrate

# Start the Rails server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0