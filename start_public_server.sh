#!/bin/bash

# GitHub Scraper - Public Server Starter
# This script starts the Rails server on all network interfaces
# so reviewers can access it from their devices

echo "🚀 Starting GitHub Scraper for public access..."
echo ""

# Get the local IP address
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Could not determine local IP address"
    echo "Please run: rails server -b 0.0.0.0 -p 3000"
    exit 1
fi

echo "📱 Share this URL with your reviewers:"
echo "   http://$LOCAL_IP:3000"
echo ""
echo "📊 Analytics dashboard:"
echo "   http://$LOCAL_IP:3000/analytics"
echo ""
echo "⚠️  Make sure your firewall allows connections on port 3000"
echo ""

# Start the Rails server
echo "🔄 Starting Rails server..."
bundle exec rails server -b 0.0.0.0 -p 3000
