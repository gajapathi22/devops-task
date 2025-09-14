# DevOps Task - Node.js Application with CI/CD Pipeline

A complete DevOps implementation featuring a Node.js application deployed to Amazon EKS with automated CI/CD pipeline using Jenkins, Docker, and Terraform.

## 🏗️ Architecture Overview

```
GitHub → Jenkins → Docker → ECR → EKS → LoadBalancer → Internet
```

- **Application**: Node.js web application
- **Containerization**: Docker
- **Container Registry**: Amazon ECR
- **Orchestration**: Amazon EKS (Kubernetes)
- **Infrastructure**: Terraform (Infrastructure as Code)
- **CI/CD**: Jenkins Pipeline
- **Cloud Provider**: AWS (ap-south-1 region)

## 📁 Project Structure

```
devops-task/
├── app.js                 # Node.js application
├── package.json           # Node.js dependencies
├── package-lock.json      # Dependency lock file
├── Dockerfile             # Container definition
├── Jenkinsfile            # CI/CD pipeline definition
├── README.md              # Project documentation
├── logoswayatt.png        # Application logo
├── .gitignore            # Git ignore rules
├── infra/                # Infrastructure as Code
│   └── terraform/
│       ├── main.tf       # Terraform configuration
│       ├── .terraform.lock.hcl
│       └── terraform.tfstate
├── k8s/                  # Kubernetes manifests
│   ├── deployment.yml    # Application deployment
│   └── service.yml       # LoadBalancer service
└── proof/                # Documentation and screenshots
```

## 🚀 Getting Started

### Prerequisites

- **AWS Account** with appropriate permissions
- **Docker** installed locally
- **AWS CLI** configured
- **kubectl** installed
- **Terraform** installed
- **Node.js** (v18+) for local development
- **Jenkins** (for CI/CD)

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/devops-task.git
   cd devops-task
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Run the application**
   ```bash
   node app.js
   ```
   Application will be available at `http://localhost:3000`

4. **Build Docker image**
   ```bash
   docker build -t devops-task .
   docker run -p 3000:3000 devops-task
   ```

## ☁️ AWS Infrastructure Setup

### 1. Deploy Infrastructure with Terraform

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply -auto-approve
```

**Resources Created:**
- EKS Cluster (`devops-task-eks`)
- ECR Repository (`devops-task`)
- VPC and Networking (using default VPC)
- IAM Roles and Policies
- Security Groups
- Node Groups (t2.small instances)

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-south-1 --name devops-task-eks
kubectl get nodes
```

### 3. Deploy Application to Kubernetes

```bash
cd k8s/

# Deploy application
kubectl apply -f deployment.yml

# Create LoadBalancer service
kubectl apply -f service.yml

# Check deployment status
kubectl get pods
kubectl get services
```

## 🐳 Docker Configuration

### Dockerfile Details

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ENV PORT=3000
EXPOSE 3000
CMD ["node", "app.js"]
```

### Docker Commands

```bash
# Build image
docker build -t devops-task:latest .

# Run locally
docker run -p 3000:3000 devops-task:latest

# Push to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 351531845608.dkr.ecr.ap-south-1.amazonaws.com
docker tag devops-task:latest 351531845608.dkr.ecr.ap-south-1.amazonaws.com/devops-task:latest
docker push 351531845608.dkr.ecr.ap-south-1.amazonaws.com/devops-task:latest
```

## 🔄 CI/CD Pipeline (Jenkins)

### Pipeline Stages

1. **Checkout** - Pull code from GitHub
2. **Environment Check** - Verify tools and dependencies
3. **Install Dependencies** - Run `npm install`
4. **Build Docker Image** - Create container image
5. **Test Docker Image** - Validate container functionality
6. **Push to ECR** - Upload to container registry
7. **Deploy to EKS** - Update Kubernetes deployment
8. **Verify Deployment** - Confirm successful deployment

### Jenkins Setup

1. **Start Jenkins locally**
   ```bash
   docker run -d --name jenkins-local -p 8081:8080 -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
   ```

2. **Access Jenkins**: `http://localhost:8081`

3. **Required Plugins**:
   - Pipeline
   - Git
   - GitHub Integration
   - Docker Pipeline
   - AWS Steps
   - Kubernetes CLI

4. **Credentials Configuration**:
   - `github-credentials`: GitHub username + Personal Access Token
   - `aws-credentials`: AWS Access Key + Secret Access Key

### Pipeline Triggers

- **Manual**: Click "Build Now" in Jenkins
- **Automatic**: Push to GitHub (requires webhook setup)
- **Scheduled**: Poll SCM every 15 minutes

## ☸️ Kubernetes Configuration

### Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-task-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: devops-task-app
  template:
    spec:
      containers:
      - name: app
        image: 351531845608.dkr.ecr.ap-south-1.amazonaws.com/devops-task:latest
        ports:
        - containerPort: 3000
```

### Service Configuration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devops-task-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
  selector:
    app: devops-task-app
```

### Useful kubectl Commands

```bash
# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services

# View logs
kubectl logs -f deployment/devops-task-app

# Scale deployment
kubectl scale deployment devops-task-app --replicas=3

# Update image
kubectl set image deployment/devops-task-app app=351531845608.dkr.ecr.ap-south-1.amazonaws.com/devops-task:v2

# Port forwarding for testing
kubectl port-forward service/devops-task-service 8080:80
```

## 📊 Monitoring and Troubleshooting

### Common Issues and Solutions

1. **ImagePullBackOff Error**
   ```bash
   # Check if image exists in ECR
   aws ecr list-images --repository-name devops-task --region ap-south-1
   
   # Re-push image if needed
   docker push 351531845608.dkr.ecr.ap-south-1.amazonaws.com/devops-