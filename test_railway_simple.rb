#!/usr/bin/env ruby

# Simple test to check if the app can start without database
puts "🔍 Testing Railway Configuration (Simple)"
puts "=" * 50

# Check environment variables
puts "Environment Variables:"
puts "  RAILS_ENV: #{ENV['RAILS_ENV'] || 'NOT SET'}"
puts "  DATABASE_URL: #{ENV['DATABASE_URL'] ? 'SET' : 'NOT SET'}"
puts "  RAILS_MASTER_KEY: #{ENV['RAILS_MASTER_KEY'] ? 'SET' : 'NOT SET'}"
puts "  GITHUB_API_TOKEN: #{ENV['GITHUB_API_TOKEN'] ? 'SET' : 'NOT SET'}"

# Check if we can load the basic Rails components
begin
  require 'bundler/setup'
  puts "✅ Bundler loaded"
rescue => e
  puts "❌ Bundler failed: #{e.message}"
end

begin
  require 'rails'
  puts "✅ Rails loaded"
rescue => e
  puts "❌ Rails failed: #{e.message}"
end

begin
  require 'puma'
  puts "✅ Puma loaded"
rescue => e
  puts "❌ Puma failed: #{e.message}"
end

puts "\n📋 Railway Checklist:"
puts "1. Add PostgreSQL service to Railway project"
puts "2. Set RAILS_ENV=production"
puts "3. Set RAILS_MASTER_KEY=a383c9517ef894b1fdaaa895da323ed7"
puts "4. Set GITHUB_API_TOKEN=your_token_here"
puts "5. DATABASE_URL will be set automatically by Railway"

puts "\n🚀 If all environment variables are set in Railway, your app should work!"
