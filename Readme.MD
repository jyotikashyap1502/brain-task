# Brain Task Project

## Running the Project

Follow these steps to run the project locally:

1. Navigate to the project directory:

```bash
cd path/to/brain-task 
```

2. Install the `serve` package globally:

```bash
sudo npm install -g serve
```

3. Verify the installation:

```bash
serve -v
```

4. Serve the production build:

```bash
serve -s dist
```

The project should now be running locally, and you can access it in your browser.

## after creating Docker File

# Build Docker image
docker build -t brain-task-app:latest .

# Run the container
docker run -d -p 3000:80 brain-task-app:latest

# go to the browser and test it.
test the project on localhost:30000

# Install or update the AWS CLI  on your system -  
# on mac
```
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg ./AWSCLIV2.pkg -target /
which aws
aws --version
```
# on windows

```
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi /qn
aws --version
```

# AWS credentials:

Login to AWS Console → https://console.aws.amazon.com
Click your username (top right) → Security credentials
Scroll to "Access keys" → Create access key
Choose "CLI" → Create
Copy Access Key ID and Secret Access Key
Save this Account ID

# Configure AWS CLI with your credentials
aws configure

# You'll be prompted to enter:
# AWS Access Key ID: [Enter your access key]
# AWS Secret Access Key: [Enter your secret key]
# Default region name: ap-south-1
# Default output format: json


# Create the repository
aws ecr create-repository \
    --repository-name brain-tasks-app \
    --region ap-south-1 \
    --image-scanning-configuration scanOnPush=true

# Expected output:
# {
#     "repository": {
#         "repositoryArn": "arn:aws:ecr:ap-south-1:590183809782:repository/brain-tasks-app",
#         "registryId": "590183809782",
#         "repositoryName": "brain-tasks-app",
#         "repositoryUri": "590183809782.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app"
#     }
# }
Copy the repositoryUri from output - you'll need it next.

# Replace <YOUR_AWS_ACCOUNT_ID> with your actual account ID (e.g., 123456789012)
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com

# Example with actual account ID:
# aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-south-1.amazonaws.com

# Expected output:
# Login Succeeded

 Tag Your Docker Image
Where: Your local terminal (in project directory)
# First, verify your local image exists
docker images | grep brain-tasks-app

# Tag the image for ECR
# Format: docker tag <local-image>:<tag> <ecr-uri>:<tag>
docker tag brain-tasks-app:latest <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app:latest

# Example with actual account ID:
# docker tag brain-tasks-app:latest 123456789012.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app:latest

# Verify the tag was created
docker images | grep brain-tasks-app
You should see TWO images now:

brain-tasks-app:latest (local)
123456789012.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app:latest (tagged for ECR)

 Push Image to ECR
Where: Your local terminal
docker push 590183809782.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app:latest
# Push the image

# Example:
# docker push <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app:latest

# You'll see output like:
# The push refers to repository [123456789012.dkr.ecr.ap-south-1.amazonaws.com/brain-tasks-app]
# 5f70bf18a086: Pushed
# latest: digest: sha256:abc123... size: 1234

Step 9: Install eksctl (if not installed) on local terminal

# Check if eksctl is installed
eksctl version

# If not installed:
# For Linux:
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# For macOS:
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# For Windows: Use Chocolatey
# choco install eksctl


Step 10: Install kubectl (if not installed)
Where: Your local terminal

# Check if kubectl is installed
kubectl version --client

# If not installed:
# For Linux:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# For macOS:
brew install kubectl

# For Windows:
# Download from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/


Step 11: Create EKS Cluster

# This takes 15-20 minutes -
eksctl create cluster \
  --name brain-tasks-cluster \
  --region ap-south-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed

# Expected output (this will take time):
# [ℹ]  eksctl version 0.x.x
# [ℹ]  using region ap-south-1
# [ℹ]  setting availability zones to [ap-south-1a ap-south-1b]
# [ℹ]  subnets for ap-south-1a - public:192.168.0.0/19 private:192.168.64.0/19
# ... (lots of creation logs)
# [✔]  EKS cluster "brain-tasks-cluster" in "ap-south-1" region is ready

# Check cluster status
eksctl get cluster --region ap-south-1

# Configure kubectl to use your cluster
aws eks update-kubeconfig \
    --region ap-south-1 \
    --name brain-tasks-cluster

# Verify nodes are ready
kubectl get nodes

# Expected output:
# NAME                             STATUS   ROLES    AGE   VERSION
# ip-192-168-x-x.ec2.internal      Ready    <none>   2m    v1.27.x
# ip-192-168-x-x.ec2.internal      Ready    <none>   2m    v1.27.x

## verify everything is set up run these commands:

# 1. ECR Repository exists
aws ecr describe-repositories --repository-names brain-tasks-app --region ap-south-1

# 2. Image is in ECR
aws ecr describe-images --repository-name brain-tasks-app --region ap-south-1

# 3. EKS Cluster is running
eksctl get cluster --region ap-south-1

# 4. kubectl is connected
kubectl get nodes

# 5. Your AWS identity
aws sts get-caller-identity


## Kubernetes Deployment 

# Navigate to your project
cd path/to/Brain-Tasks-App

# Create k8s folder for Kubernetes files
mkdir k8s

# Navigate to k8s folder
cd k8s

# Create a file named deployment.yaml what this will do 

Creates 2 replicas (pods) of your app
Uses your ECR image
Exposes port 3000
Sets resource limits
Adds health checks

#  Create Service YAML inside k8s folder what this will do

Creates AWS LoadBalancer
Routes external traffic (port 80) to your app (port 3000)
Makes your app accessible from internet

# Deploy to Kubernetes  run comman in k8s folder
kubectl apply -f deployment.yaml
```

**Expected output:**
```
deployment.apps/brain-tasks-deployment created

# Check deployment status
kubectl get deployments

# Expected output:
# NAME                                      READY   STATUS    RESTARTS   AGE
  brain-tasks-deployment-54d5bk664b-66nm   1/1     Running   0          13s
  brain-tasks-deployment-54d7b66k4b-ssn6   1/1     Running   0          13s

# Apply Service (Create LoadBalancer)
```
kubectl apply -f service.yaml
```

**Expected output:**

service/brain-tasks-service created
```
kubectl get service brain-tasks-service
```
# Get LoadBalancer URL
**Initial output (LoadBalancer is being created):**
```
NAME                  TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
brain-tasks-service   LoadBalancer   10.100.x.x      d298fe68d5f43509fc92ad2350a0f6-641131410.ap-south-1.elb.amazonaws.com     80:32xxx/TCP   15s
```

# Access Your Application on Web Browser
# In terminal, get the URL
kubectl get service brain-tasks-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Copy the URL and open in browser:**
```
http://a1b2c3d4e5f6g7h8i9j0.ap-south-1.elb.amazonaws.com

# Step 8: Fix Security Group Connectivity (If LoadBalancer Not Accessible)

If the app is running inside the pod but not accessible from the browser, ensure the LoadBalancer Security Group and Node Security Group allow communication.

# 1️⃣ Get LoadBalancer Security Group
```
aws elb describe-load-balancers --region ap-south-1 \
  --query "LoadBalancerDescriptions[*].{Name:LoadBalancerName,SGs:SecurityGroups,VpcId:VPCId}" \
  --output table
```
```
Example Output:

|  Name   |  ad298fe685d5f43509fc92ad2350a0f6  |
|  SGs    |  sg-01a2dc9e8f1ad69d8               |
|  VPC ID |  vpc-0421edd09072314bb              |
```

# 2️⃣ Get Node Security Group
```
kubectl get nodes -o wide
```

Then:
```
aws ec2 describe-instances --region ap-south-1 \
  --filters "Name=private-ip-address,Values=192.168.40.133,192.168.77.191" \
  --query "Reservations[].Instances[].{InstanceId:InstanceId,VpcId:VpcId,SGs:SecurityGroups[*].GroupId}" \
  --output table
```

Output Example:

| InstanceId | i-050fe911a18a62fb6 |
| SGs        | sg-0374bf12e316c1800 |
| VPC ID     | vpc-0421edd09072314bb |


# 3️⃣ Authorize Ingress (One-time setup)
```
aws ec2 authorize-security-group-ingress \
  --group-id sg-0374bf12e316c1800 \
  --protocol tcp --port 32213 \
  --source-group sg-01a2dc9e8f1ad69d8 \
  --region ap-south-1
```

If you see: InvalidPermission.Duplicate, that’s fine — it means the rule already exists.

After this step, your LoadBalancer and Node are properly connected, and the app becomes publicly accessible ✅

### Step 9: LoadBalancer Details (For Submission)
```
Property	Value
LoadBalancer Name	ad298fe685d5f43509fc92ad2350a0f6
DNS Name	ad298fe685d5f43509fc92ad2350a0f6-641131410.ap-south-1.elb.amazonaws.com
VPC ID	vpc-0421edd09072314bb
LoadBalancer Security Group	sg-01a2dc9e8f1ad69d8
Node Security Group	sg-0374bf12e316c1800
LoadBalancer ARN	arn:aws:elasticloadbalancing:ap-south-1:590183809782:loadbalancer/ad298fe685d5f43509fc92ad2350a0f6
```

## ✅ Final Status:
All pods running successfully, LoadBalancer active, app publicly accessible on browser via AWS ELB DNS


# Verification Checklist ✅
Before moving to next phase, verify:

# ✅ Deployment exists
kubectl get deployment brain-tasks-deployment

# ✅ 2 Pods running
kubectl get pods | grep Running

# ✅ Service created
kubectl get service brain-tasks-service

# ✅ LoadBalancer has external IP
kubectl get service brain-tasks-service | grep elb

# ✅ Application accessible
curl http://$(kubectl get service brain-tasks-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# ✅ Pods are healthy
kubectl get pods -o jsonpath='{.items[*].status.phase}'


# Brain Tasks App - CI/CD Enabled
Testing 

