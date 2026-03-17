#!/bin/bash
# June App - Deploy API to DigitalOcean server
# Usage: ./deploy.sh

SERVER="root@167.71.170.219"
APP_DIR="/home/june"
API_DIR="$APP_DIR/api"

echo "🦅 Deploying June API..."

# Create app directory on server
ssh $SERVER "mkdir -p $API_DIR"

# Copy API files
echo "📦 Copying API files..."
rsync -avz --exclude 'node_modules' --exclude '.env' api/ $SERVER:$API_DIR/

# SSH in and set up
ssh $SERVER << 'REMOTE'
  set -e
  APP_DIR="/home/june"
  API_DIR="$APP_DIR/api"

  echo "📦 Installing dependencies..."
  cd $API_DIR
  npm install --production

  echo "🗄️  Setting up database..."
  # Run migration (assumes .env is already in place with DATABASE_URL)
  if [ -f .env ]; then
    source .env
    # Extract connection info and run migration
    psql "$DATABASE_URL" -f migrations/001_initial.sql 2>/dev/null || echo "Migration may have already run"
  else
    echo "⚠️  No .env found — create one at $API_DIR/.env before starting"
  fi

  echo "🚀 Starting/restarting with PM2..."
  if pm2 describe june-api > /dev/null 2>&1; then
    pm2 restart june-api
  else
    pm2 start server.js --name june-api
  fi
  pm2 save

  echo "✅ June API deployed!"
REMOTE

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "  1. Create /home/june/api/.env with your DATABASE_URL and JWT_SECRET"
echo "  2. Add Nginx config: sudo nano /etc/nginx/sites-available/june"
echo "  3. Enable: sudo ln -s /etc/nginx/sites-available/june /etc/nginx/sites-enabled/"
echo "  4. Reload Nginx: sudo nginx -s reload"
