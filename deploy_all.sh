#!/bin/bash

# Image list
images=(
  nsulliv7/ser516-defects-over-time:latest
  nsulliv7/ser516-cc:latest
  nsulliv7/ser516-cyclo:latest
  nsulliv7/ser516-hal:latest
  nsulliv7/ser516-ici:latest
  nsulliv7/ser516-loc:latest
  nsulliv7/ser516-mttr:latest
  mkapure/app-java-backend:latest
  mkapure/app-code-comment-coverage-backend:latest
  gopu007/app-instability
  gopu007/app-defect-score
  gopu007/app-lcomhs
  gopu007/app-lcom4
  gopu007/app-defect-density
  gopu007/app-afferent-coupling
  # gopu007/app-efferent-coupling
  mkapure/app-fan-in-service
  mkapure/app-fan-out-service
  nsulliv7/ser516-middleware
)

# List of known images and their ports
port_mapping="nsulliv7/ser516-defects-over-time:latest=5000
nsulliv7/ser516-cc:latest=5000
nsulliv7/ser516-cyclo:latest=5000
nsulliv7/ser516-hal:latest=5000
nsulliv7/ser516-ici:latest=5000
nsulliv7/ser516-loc:latest=5000
nsulliv7/ser516-mttr:latest=5000
mkapure/app-java-backend:latest=8080
mkapure/app-code-comment-coverage-backend:latest=5006
gopu007/app-instability=8000
gopu007/app-defect-score=8000
gopu007/app-lcomhs=8000
gopu007/app-lcom4=8000
gopu007/app-defect-density=8083
gopu007/app-afferent-coupling=8083
# gopu007/app-efferent-coupling=8087
mkapure/app-fan-in-service=8001
mkapure/app-fan-out-service=8002
nsulliv7/ser516-middleware=5000"

# Create log directory if it doesn't exist
mkdir -p logs

# Function to get port for an image
get_port() {
  local image=$1
  local port=$(echo "$port_mapping" | grep "^$image=" | cut -d'=' -f2)
  echo "$port"
}

# Function to handle port conflicts - check if port is already in use
is_port_in_use() {
  local port=$1
  if lsof -i :$port > /dev/null 2>&1; then
    return 0  # Port is in use
  else
    return 1  # Port is not in use
  fi
}

# Function to kill existing port forwards
cleanup_port_forwards() {
  echo "🧹 Cleaning up existing port forwards..."
  
  # Find and kill all kubectl port-forward processes
  pkill -f "kubectl port-forward" || true
  
  # Small delay to ensure processes have terminated
  sleep 2
}

echo "🔄 Starting deployment of all services..."

# First, deploy all services
for image in "${images[@]}"; do
  base_name=$(echo "$image" | sed 's|.*/||; s|:|-|g')
  name=$(echo "$base_name" | tr '[:upper:]' '[:lower:]')
  container_port=$(get_port "$image")
  
  if [[ -z "$container_port" ]]; then
    echo "⚠️ WARNING: No port mapping found for $image. Defaulting to 8080."
    container_port=8080
  fi
  
  echo "🚀 Deploying $image as $name on port $container_port..."
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
    spec:
      containers:
      - name: $name
        image: $image
        ports:
        - containerPort: $container_port
---
apiVersion: v1
kind: Service
metadata:
  name: ${name}-service
spec:
  selector:
    app: $name
  ports:
  - protocol: TCP
    port: 80
    targetPort: $container_port
  type: NodePort
EOF
done

echo "✅ All deployments submitted. Waiting for pods to be ready..."

# Wait for deployments to become ready
sleep 30  # Initial wait time to allow pods to start

# Clean up any existing port forwards first
cleanup_port_forwards

# Now set up port forwarding for all deployed services
echo "🔌 Setting up port forwarding for all services..."

# Track port forward PIDs for cleanup
port_forward_pids=()

# Setup port forwarding
for image in "${images[@]}"; do
  base_name=$(echo "$image" | sed 's|.*/||; s|:|-|g')
  deployment_name=$(echo "$base_name" | tr '[:upper:]' '[:lower:]')
  container_port=$(get_port "$image")
  
  if [[ -z "$container_port" ]]; then
    container_port=8080
  fi
  
  # Get the pod for this deployment
  pod=$(kubectl get pods | grep "$deployment_name" | awk '{print $1}' | head -n 1)
  
  if [[ -z "$pod" ]]; then
    echo "⚠️ No pod found for deployment $deployment_name. Skipping port forward."
    continue
  fi
  
  # Check if the port is already in use
  if is_port_in_use "$container_port"; then
    echo "⚠️ Port $container_port is already in use. Trying alternative port for $deployment_name."
    # Try to find an alternative port by incrementing
    alt_port=$((container_port + 1000))
    while is_port_in_use "$alt_port" && [ "$alt_port" -lt "$((container_port + 1100))" ]; do
      alt_port=$((alt_port + 1))
    done
    if is_port_in_use "$alt_port"; then
      echo "❌ Could not find an available port for $deployment_name. Skipping."
      continue
    fi
    echo "🔄 Using alternative port $alt_port for $deployment_name (original port: $container_port)"
    local_port=$alt_port
  else
    local_port=$container_port
  fi
  
  echo "🔌 Setting up port forward for $pod: $local_port -> $container_port"
  nohup kubectl port-forward "$pod" "$local_port:$container_port" > "logs/port-forward-$deployment_name.log" 2>&1 &
  port_forward_pid=$!
  port_forward_pids+=($port_forward_pid)
  
  # Store in a mapping file for future reference
  echo "$deployment_name,$pod,$local_port,$container_port,$port_forward_pid" >> port_forwards.csv
  
  # Small delay to avoid overwhelming the system
  sleep 1
done

echo "✅ Port forwarding setup complete. Port mappings saved to port_forwards.csv"
echo "📋 Currently active port forwards:"
cat port_forwards.csv | column -t -s ','

# Provide a cleanup function
cat > stop_port_forwards.sh <<EOF
#!/bin/bash
echo "🛑 Stopping all port forwards..."
if [ -f "port_forwards.csv" ]; then
  while IFS=, read -r deployment pod local_port container_port pid; do
    if ps -p \$pid > /dev/null; then
      echo "Stopping port forward for \$deployment (\$local_port -> \$container_port, PID: \$pid)"
      kill \$pid
    fi
  done < port_forwards.csv
  rm port_forwards.csv
else
  echo "No port forwards file found. Killing all kubectl port-forward processes..."
  pkill -f "kubectl port-forward" || true
fi
echo "✅ All port forwards stopped."
EOF

chmod +x stop_port_forwards.sh

echo "⚠️  To stop all port forwards, run: ./stop_port_forwards.sh"
echo "🌐 You can now access services at their respective localhost ports"