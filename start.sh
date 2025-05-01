#!/bin/bash

brew upgrade --cask docker
brew upgrade docker-compose
docker-compose down -v --remove-orphans
docker system prune -af
set -e  # Exit immediately if a command exits with a non-zero status

# Helper function to check the return code of the last command
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting."
    exit 1
  fi
}

# Step 1: Pull latest images
echo "Pulling latest Docker images..."
docker-compose pull
check_success "docker-compose pull"

# Step 2: Start containers in detached mode
echo "Starting services..."
docker-compose up -d
check_success "docker-compose up"

# Step 3: Wait until all containers are healthy or running
echo "Waiting for containers to be healthy or running..."

wait_for_containers() {
  local timeout=60
  local interval=5
  local elapsed=0

  while true; do
    unhealthy=$(docker ps --format "{{.Names}} {{.Status}}" | grep -Ev 'healthy|Up' || true)

    if [[ -z "$unhealthy" ]]; then
      echo "All containers are healthy and running."
      return 0
    fi

    if (( elapsed >= timeout )); then
      echo "Timeout: Some containers are not healthy or not running:"
      echo "$unhealthy"
      return 1
    fi

    echo "Waiting... [$elapsed/$timeout seconds]"
    sleep $interval
    ((elapsed+=interval))
  done
}

wait_for_containers
check_success "Container readiness check"
