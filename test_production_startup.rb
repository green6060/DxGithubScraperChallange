#!/usr/bin/env ruby

# Test production startup configuration
puts "🔍 Testing Production Startup Configuration"
puts "=" * 60

# Set production environment
ENV['RAILS_ENV'] = 'production'

# Check if we can load Rails
begin
  require_relative 'config/environment'
  puts "✅ Rails environment loaded successfully"
rescue => e
  puts "❌ Failed to load Rails environment: #{e.message}"
  puts "   Error class: #{e.class.name}"
  exit 1
end

# Check database connection
begin
  ActiveRecord::Base.connection
  puts "✅ Database connection established"
rescue => e
  puts "❌ Database connection failed: #{e.message}"
  puts "   Error class: #{e.class.name}"
  exit 1
end

# Check if we can run migrations
begin
  ActiveRecord::MigrationContext.new('db/migrate').migrate
  puts "✅ Database migrations completed"
rescue => e
  puts "❌ Database migration failed: #{e.message}"
  puts "   Error class: #{e.class.name}"
  exit 1
end

# Check if we can start the server (without actually starting it)
begin
  # Test if Puma can be loaded
  require 'puma'
  puts "✅ Puma server can be loaded"
rescue => e
  puts "❌ Puma server failed to load: #{e.message}"
  exit 1
end

puts "\n🎉 All production startup checks passed!"
puts "   Your Rails app should start successfully in production."
