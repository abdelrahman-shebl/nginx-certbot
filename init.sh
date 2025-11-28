#!/bin/bash

echo "Setting up shared nginx for multiple apps..."

# Define base paths (MODIFY THESE to match your actual paths)
NGINX_DIR="/home/ubuntu/nginx-certbot"
BACKEND_DIR="/home/ubuntu/backend-deployment/Fermy"
FRONTEND_DIR="/home/ubuntu/frontend-deployment/firmy-legal-platform"
DASHBOARD_DIR="/home/ubuntu/dashboard-deployment/firmy-admin-dashboard"


# Create shared network if it doesn't exist
echo "Creating shared network..."
docker network create shared-network 2>/dev/null || echo "Network already exists"

# Start shared nginx first
echo "Starting shared nginx..."
cd $NGINX_DIR
docker compose -f docker-compose-nginx.yml up -d nginx

# Start all your apps
echo "Starting backend..."
cd $BACKEND_DIR && docker compose -f docker-compose.yml up -d

echo "Starting frontend..."
cd $FRONTEND_DIR && docker compose -f docker-compose.yml up -d

echo "Starting dashboard..."
cd $DASHBOARD_DIR && docker compose -f docker-compose.yml up -d

# Back to nginx directory
cd $NGINX_DIR

# Wait for services
echo "Waiting for services to start..."
sleep 10

# Get certificate for karofa.com and www.karofa.com (ONE certificate for both)
echo "Getting certificate for karofa.com + www.karofa.com..."
docker compose -f docker-compose-nginx.yml run --rm certbot \
  certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email sheblabdo00@gmail.com \
  --agree-tos \
  --no-eff-email \
  -d karofa.com -d www.karofa.com

# Get certificate for dashboard.karofa
echo "Getting certificate for dashboard.karofa..."
docker compose -f docker-compose-nginx.yml run --rm certbot \
  certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email sheblabdo00@gmail.com \
  --agree-tos \
  --no-eff-email \
  -d dashboard.karofa

# Get certificate for api.karofa.com
echo "Getting certificate for api.karofa.com..."
docker compose -f docker-compose-nginx.yml run --rm certbot \
  certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email sheblabdo00@gmail.com \
  --agree-tos \
  --no-eff-email \
  -d api.karofa.com

# Reload nginx with all certificates
echo "Reloading nginx..."
docker compose -f docker-compose-nginx.yml restart nginx

echo ""
echo "✓ Setup complete!"
echo ""
echo "Certificates created:"
echo "  - /etc/letsencrypt/live/karofa.com/ (for karofa.com + www.karofa.com)"
echo "  - /etc/letsencrypt/live/dashboard.karofa/"
echo "  - /etc/letsencrypt/live/api.karofa.com/"
echo ""
echo "Services running:"
echo "  - https://karofa.com (frontend)"
echo "  - https://dashboard.karofa (dashboard)"
echo "  - https://api.karofa.com (backend)"
echo ""
echo "Add to crontab for auto-renewal:"
echo "0 3 * * * docker compose -f $NGINX_DIR/docker-compose-nginx.yml run --rm certbot renew && docker compose -f $NGINX_DIR/docker-compose-nginx.yml restart nginx"