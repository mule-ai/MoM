# Use the official Ruby image
FROM ruby:3.2.0-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock first for better caching
COPY Gemfile Gemfile.lock* ./

# Install Ruby dependencies
RUN bundle install

# Copy the application code
COPY . .

# Make entrypoint executable
RUN chmod +x docker-entrypoint.sh

# Generate gRPC code manually
RUN echo "Generating protobuf files..." && \
    bundle exec grpc_tools_ruby_protoc -I lib/proto --ruby_out=lib/proto --grpc_out=lib/proto lib/proto/mule.proto && \
    bundle exec grpc_tools_ruby_protoc -I lib/proto --ruby_out=lib/proto --grpc_out=lib/proto lib/proto/mule_client.proto && \
    echo "Files generated:" && \
    ls -la lib/proto/ && \
    echo "Fixing require paths..." && \
    sed -i "s/require 'mule_pb'/require_relative 'mule_pb'/" lib/proto/mule_services_pb.rb && \
    sed -i "s/require 'mule_client_pb'/require_relative 'mule_client_pb'/" lib/proto/mule_client_services_pb.rb && \
    echo "Fixed files"

# Set proper permissions
RUN chmod -R 755 /app

# Expose ports
EXPOSE 3000 50051

# Set environment variables
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV SECRET_KEY_BASE=placeholder_will_be_generated_at_runtime
ENV DB_USERNAME=mom
ENV DB_PASSWORD=password
ENV DB_HOST=localhost
ENV DB_NAME=mom_production

# Start both Rails server and ensure gRPC server starts
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]