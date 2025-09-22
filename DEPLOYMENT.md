# Deployment Guide

## Quick Hosting Options for Reviewers

### Option 1: Railway (Recommended - 5 minutes)

1. **Sign up at [Railway.app](https://railway.app)**
2. **Connect your GitHub account**
3. **Deploy from GitHub:**

   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose this repository
   - Railway will automatically detect it's a Rails app

4. **Set Environment Variables:**

   - Go to your project settings
   - Add these environment variables:
     ```
     GITHUB_API_TOKEN=your_github_token_here
     RAILS_ENV=production
     RAILS_MASTER_KEY=your_master_key_here
     ```

5. **Deploy:** Railway will automatically build and deploy

**Result:** Your app will be live at `https://your-app-name.railway.app`

---

### Option 2: Heroku (10 minutes)

1. **Install Heroku CLI**
2. **Login and create app:**

   ```bash
   heroku login
   heroku create your-app-name
   ```

3. **Add PostgreSQL:**

   ```bash
   heroku addons:create heroku-postgresql:mini
   ```

4. **Set environment variables:**

   ```bash
   heroku config:set GITHUB_API_TOKEN=your_token_here
   heroku config:set RAILS_ENV=production
   ```

5. **Deploy:**
   ```bash
   git push heroku main
   heroku run rails db:migrate
   ```

---

### Option 3: Render (5 minutes)

1. **Sign up at [Render.com](https://render.com)**
2. **Connect GitHub and create new Web Service**
3. **Configure:**
   - Build Command: `bundle install && bundle exec rails assets:precompile`
   - Start Command: `bundle exec rails server -p $PORT -e production`
4. **Add environment variables in dashboard**
5. **Deploy**

---

### Option 4: Local Network Sharing (Immediate)

If reviewers are on the same network:

1. **Find your IP address:**

   ```bash
   # On Mac/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1

   # On Windows
   ipconfig
   ```

2. **Start Rails on all interfaces:**

   ```bash
   rails server -b 0.0.0.0 -p 3000
   ```

3. **Share the URL:** `http://YOUR_IP_ADDRESS:3000`

---

## Environment Variables Needed

```bash
GITHUB_API_TOKEN=ghp_your_token_here
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here
```

## Database Setup

The app will automatically run migrations on first deploy. No manual setup needed.

## Quick Test

Once deployed, visit:

- Main dashboard: `https://your-app-url.com`
- Analytics: `https://your-app-url.com/analytics`

## Troubleshooting

- **Database errors:** Make sure PostgreSQL is added as an addon
- **API errors:** Verify your GitHub token has proper permissions
- **Build errors:** Check that all gems are in the Gemfile
