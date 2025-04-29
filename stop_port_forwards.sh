#!/bin/bash
echo "🛑 Stopping all port forwards..."
if [ -f "port_forwards.csv" ]; then
  while IFS=, read -r deployment pod local_port container_port pid; do
    if ps -p $pid > /dev/null; then
      echo "Stopping port forward for $deployment ($local_port -> $container_port, PID: $pid)"
      kill $pid
    fi
  done < port_forwards.csv
  rm port_forwards.csv
else
  echo "No port forwards file found. Killing all kubectl port-forward processes..."
  pkill -f "kubectl port-forward" || true
fi
echo "✅ All port forwards stopped."
