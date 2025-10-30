#!/bin/bash
set -e

echo "Starting Kubernetes deployment..."

# Update kubeconfig
aws eks update-kubeconfig --region ap-south-1 --name brain-tasks-cluster

# Apply Kubernetes manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Wait for rollout
kubectl rollout status deployment/brain-tasks-deployment

# Get deployment info
echo "Deployment completed successfully!"
kubectl get pods
kubectl get svc brain-tasks-service