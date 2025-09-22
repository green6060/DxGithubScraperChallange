#!/usr/bin/env ruby

# Test script to verify Railway configuration
puts "🔍 Testing Railway Configuration..."

# Check if DATABASE_URL is set
if ENV['DATABASE_URL']
  puts "✅ DATABASE_URL is set: #{ENV['DATABASE_URL'][0..50]}..."
else
  puts "❌ DATABASE_URL is not set"
end

# Check if RAILS_ENV is set
if ENV['RAILS_ENV']
  puts "✅ RAILS_ENV is set: #{ENV['RAILS_ENV']}"
else
  puts "❌ RAILS_ENV is not set"
end

# Check if RAILS_MASTER_KEY is set
if ENV['RAILS_MASTER_KEY']
  puts "✅ RAILS_MASTER_KEY is set: #{ENV['RAILS_MASTER_KEY'][0..10]}..."
else
  puts "❌ RAILS_MASTER_KEY is not set"
end

# Check if GITHUB_API_TOKEN is set
if ENV['GITHUB_API_TOKEN']
  puts "✅ GITHUB_API_TOKEN is set: #{ENV['GITHUB_API_TOKEN'][0..10]}..."
else
  puts "❌ GITHUB_API_TOKEN is not set"
end

puts "\n📋 Required Environment Variables for Railway:"
puts "1. DATABASE_URL (automatically set by Railway when you add PostgreSQL)"
puts "2. RAILS_ENV=production"
puts "3. RAILS_MASTER_KEY=your_master_key_here"
puts "4. GITHUB_API_TOKEN=your_github_token_here"

puts "\n🚀 Next Steps:"
puts "1. Make sure you added a PostgreSQL service to your Railway project"
puts "2. Set RAILS_ENV=production in Railway variables"
puts "3. Set RAILS_MASTER_KEY=your_master_key_here in Railway variables"
puts "4. Set GITHUB_API_TOKEN=your_github_token_here in Railway variables"
puts "5. Redeploy your app"
