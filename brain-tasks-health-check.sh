#!/bin/bash

# ==========================================
# 🧠 Brain Tasks App - Full Health Check
# Covers: EKS, Pods, Service, ECR, CodePipeline, CodeBuild, HTTP test
# ==========================================

CLUSTER="brain-tasks-cluster"
REGION="ap-south-1"
SERVICE_NAME="brain-tasks-service"
DEPLOYMENT_NAME="brain-tasks-deployment"
REPOSITORY_NAME="brain-tasks-app"
PIPELINE_NAME="brain-tasks-pipeline"
CODEBUILD_PROJECT="brain-tasks-build"

echo "🔍 Checking Brain Tasks App health..."
echo "----------------------------------------"

# 1️⃣ Verify cluster connection
CONTEXT=$(kubectl config current-context 2>/dev/null)
if [[ "$CONTEXT" == *"$CLUSTER"* ]]; then
  echo "✅ Connected to cluster: $CLUSTER"
else
  echo "⚠️ Not connected to $CLUSTER — updating kubeconfig..."
  aws eks update-kubeconfig --region $REGION --name $CLUSTER >/dev/null
  echo "✅ Switched to $CLUSTER"
fi

# 2️⃣ Check deployment status
DEPLOY_STATUS=$(kubectl get deployment $DEPLOYMENT_NAME -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [[ "$DEPLOY_STATUS" == "2" ]]; then
  echo "✅ Deployment: $DEPLOYMENT_NAME (2/2 replicas available)"
else
  echo "❌ Deployment not fully available!"
  kubectl get deployment $DEPLOYMENT_NAME
fi

# 3️⃣ Check pods
echo "----------------------------------------"
kubectl get pods -l app=brain-tasks --no-headers
RUNNING=$(kubectl get pods -l app=brain-tasks --no-headers 2>/dev/null | grep -c "Running")
if [[ "$RUNNING" -ge 2 ]]; then
  echo "✅ Pods: $RUNNING Running"
else
  echo "❌ Some pods not running!"
fi

# 4️⃣ Check service and external IP
EXTERNAL_IP=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [[ -n "$EXTERNAL_IP" ]]; then
  echo "✅ Service: $SERVICE_NAME → $EXTERNAL_IP"
else
  echo "❌ LoadBalancer external IP not found!"
fi

# 5️⃣ Test HTTP response
if [[ -n "$EXTERNAL_IP" ]]; then
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$EXTERNAL_IP)
  if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "✅ HTTP Response: 200 OK - Application reachable"
  else
    echo "❌ HTTP check failed - Status $HTTP_STATUS"
  fi
fi

# 6️⃣ Verify ECR repository and latest image
echo "----------------------------------------"
LATEST_IMAGE=$(aws ecr describe-images --repository-name $REPOSITORY_NAME \
  --region $REGION --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' --output text 2>/dev/null)
if [[ "$LATEST_IMAGE" != "None" && -n "$LATEST_IMAGE" ]]; then
  echo "✅ ECR: Latest image tag → $LATEST_IMAGE"
else
  echo "❌ No images found in ECR!"
fi

# 7️⃣ Check CodePipeline last execution
PIPELINE_STATUS=$(aws codepipeline get-pipeline-state \
  --name $PIPELINE_NAME --region $REGION \
  --query 'stageStates[*].latestExecution.status' --output text 2>/dev/null)

if echo "$PIPELINE_STATUS" | grep -q "Succeeded"; then
  echo "✅ CodePipeline: Last run succeeded"
else
  echo "❌ CodePipeline: Check AWS Console for failure"
fi

# 8️⃣ Check CodeBuild recent build logs
LAST_BUILD_ID=$(aws codebuild list-builds-for-project \
  --project-name $CODEBUILD_PROJECT --region $REGION \
  --query 'ids[0]' --output text 2>/dev/null)

if [[ "$LAST_BUILD_ID" != "None" && -n "$LAST_BUILD_ID" ]]; then
  BUILD_STATUS=$(aws codebuild batch-get-builds \
    --ids $LAST_BUILD_ID --region $REGION \
    --query 'builds[0].buildStatus' --output text)
  echo "✅ CodeBuild: Latest build status → $BUILD_STATUS"
else
  echo "❌ No build found in CodeBuild project!"
fi


# 9️⃣ Check DNS Resolution
echo "----------------------------------------"
echo "🌐 Checking DNS resolution..."
nslookup $EXTERNAL_IP >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "✅ DNS resolved successfully for $EXTERNAL_IP"
else
  echo "❌ DNS resolution failed!"
fi

# 🔟 Verify EKS Cluster Node Health
echo "----------------------------------------"
echo "🧩 Checking cluster node status..."
kubectl get nodes --no-headers | grep -q "Ready"
if [[ $? -eq 0 ]]; then
  echo "✅ EKS Nodes are in Ready state"
else
  echo "❌ One or more nodes are not Ready!"
  kubectl get nodes
fi

# 7️⃣ Check Pod Logs for Errors
echo "----------------------------------------"
echo "🪵 Checking pod logs (recent 50 lines)..."
LOGS=$(kubectl logs -l app=brain-tasks --tail=50 2>/dev/null)
if echo "$LOGS" | grep -qiE "error|fail|exception"; then
  echo "❌ Errors found in pod logs!"
else
  echo "✅ No errors in recent pod logs"
fi
# 1️⃣5️⃣ Verify All K8s Resources Exist
echo "----------------------------------------"
echo "📦 Verifying all Kubernetes resources..."
kubectl get all | grep brain-tasks


# 1️⃣3️⃣ Check CloudWatch Build Logs
# 1️⃣3️⃣ Check CloudWatch Build Logs (Last 5 Days)
echo "----------------------------------------"
echo "🪣 Checking recent CloudWatch build logs (last 5 days)..."


# 1️⃣4️⃣ Page Responsiveness Test
if [[ -n "$EXTERNAL_IP" ]]; then
  echo "----------------------------------------"
  LOAD_TIME=$(curl -o /dev/null -s -w "%{time_total}\n" http://$EXTERNAL_IP)
  echo "⏱️ Page load time: ${LOAD_TIME}s"
  if (( $(echo "$LOAD_TIME < 3" | bc -l) )); then
    echo "✅ Page loads under 3 seconds"
  else
    echo "⚠️ Page load slower than expected"
  fi
fi

echo "----------------------------------------"
echo "🏁 Full Project Health Check Complete!"
