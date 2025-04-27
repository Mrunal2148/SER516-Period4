#!/bin/bash

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
  smitmaheshpanchal/instability:latest
  smitmaheshpanchal/defect-score:latest
  smitmaheshpanchal/lcomhs:latest
  smitmaheshpanchal/lcom4:latest
  smitmaheshpanchal/defect-density:latest
  smitmaheshpanchal/afferent-coupling:latest
  smitmaheshpanchal/efferent-coupling:latest
  patilaniket14/metric-frontend:latest
  smitmaheshpanchal/middleware:latest
  smitmaheshpanchal/benchmark:latest
  mkapure/app-fan-in-service:latest
  mkapure/app-fan-out-service:latest
)

for image in "${images[@]}"; do
  base_name=$(echo "$image" | sed 's|.*/||; s|:|-|g')
  name=$(echo "$base_name" | tr '[:upper:]' '[:lower:]')

  echo "Deploying $image as $name..."

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
        - containerPort: 8080
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
      targetPort: 8080
  type: NodePort
EOF

done

echo "✅ All deployments submitted."
