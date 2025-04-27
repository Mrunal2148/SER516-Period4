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
port_mapping="nsulliv7/ser516-defects-over-time:latest=5004
nsulliv7/ser516-cc:latest=5001
nsulliv7/ser516-cyclo:latest=5005
nsulliv7/ser516-hal:latest=5006
nsulliv7/ser516-ici:latest=5009
nsulliv7/ser516-loc:latest=5002
nsulliv7/ser516-mttr:latest=5003
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


# Function to get port for an image
get_port() {
  local image=$1
  local port=$(echo "$port_mapping" | grep "^$image=" | cut -d'=' -f2)
  echo "$port"
}

echo "🔄 Starting deployment of all services..."

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

echo "✅ All deployments submitted."

#done till - bringing the pods up
#port fowarding
#list down the commands here
#kubectl get pods