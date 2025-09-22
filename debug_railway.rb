#!/usr/bin/env ruby

puts "🔍 Railway Configuration Debug"
puts "=" * 50

# Check DATABASE_URL
if ENV['DATABASE_URL']
  puts "✅ DATABASE_URL is set"
  puts "   Format: #{ENV['DATABASE_URL'].include?('postgresql://') ? 'Correct' : 'Incorrect'}"
  puts "   Length: #{ENV['DATABASE_URL'].length} characters"
else
  puts "❌ DATABASE_URL is missing"
  puts "   → Add PostgreSQL service to Railway project"
end

# Check RAILS_ENV
if ENV['RAILS_ENV'] == 'production'
  puts "✅ RAILS_ENV is set to production"
elsif ENV['RAILS_ENV']
  puts "⚠️  RAILS_ENV is set to: #{ENV['RAILS_ENV']} (should be 'production')"
else
  puts "❌ RAILS_ENV is missing"
  puts "   → Set RAILS_ENV=production in Railway"
end

# Check RAILS_MASTER_KEY
if ENV['RAILS_MASTER_KEY']
  puts "✅ RAILS_MASTER_KEY is set"
  puts "   Length: #{ENV['RAILS_MASTER_KEY'].length} characters"
else
  puts "❌ RAILS_MASTER_KEY is missing"
  puts "   → Set RAILS_MASTER_KEY=a383c9517ef894b1fdaaa895da323ed7"
end

# Check GITHUB_API_TOKEN
if ENV['GITHUB_API_TOKEN']
  puts "✅ GITHUB_API_TOKEN is set"
  puts "   Length: #{ENV['GITHUB_API_TOKEN'].length} characters"
else
  puts "❌ GITHUB_API_TOKEN is missing"
  puts "   → Set GITHUB_API_TOKEN=your_token_here"
end

puts "\n📋 Railway Setup Checklist:"
puts "1. ✅ PostgreSQL service added to project"
puts "2. ✅ DATABASE_URL automatically set by Railway"
puts "3. ✅ RAILS_ENV=production set in variables"
puts "4. ✅ RAILS_MASTER_KEY set in variables"
puts "5. ✅ GITHUB_API_TOKEN set in variables"

puts "\n🚀 If all checks pass, your app should deploy successfully!"
