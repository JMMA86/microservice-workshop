# Infrastructure Deployment Process

## Overview

The infrastructure deployment process consists of three main phases executed through PowerShell scripts. Each script handles a specific part of the deployment pipeline to ensure a complete and reliable microservices infrastructure on Azure.

## Prerequisites

Before running the deployment scripts, ensure you have:

- **Azure CLI** installed and configured
- **Docker** installed for image building
- **kubectl** installed for Kubernetes management
- **Terraform** installed for infrastructure provisioning
- **PowerShell** (Windows PowerShell or PowerShell Core)

## Deployment Scripts

### 1. Infrastructure Provisioning (`deploy-infra.ps1`)

**Purpose**: Creates and configures the Azure infrastructure using Terraform.

#### Script Parameters
```powershell
.\scripts\deploy-infra.ps1 -Deploy [all|bootstrap|dev]
```

#### Deployment Phases

##### Phase 1: Bootstrap (Remote State)
```powershell
# Creates Terraform remote state infrastructure
- Creates Azure Storage Account for Terraform state
- Sets up state lock mechanism
- Configures backend for subsequent deployments
```

**What it creates:**
- Resource Group for Terraform state
- Storage Account for `.tfstate` files
- Blob Container for state storage

##### Phase 2: Development Environment
```powershell
# Deploys main infrastructure components
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS) cluster
- Virtual Network and subnets
- Security groups and access policies
```

**What it creates:**
- AKS cluster with node pools
- ACR for container images
- Networking infrastructure
- IAM roles and permissions

#### Usage Examples
```powershell
# Deploy everything (recommended for first run)
.\scripts\deploy-infra.ps1 -Deploy all

# Deploy only bootstrap phase
.\scripts\deploy-infra.ps1 -Deploy bootstrap

# Deploy only development environment
.\scripts\deploy-infra.ps1 -Deploy dev
```

---

### 2. Container Image Management (`deploy-acr.ps1`)

**Purpose**: Builds Docker images for all microservices and pushes them to Azure Container Registry.

#### Process Flow

1. **Authentication**
   ```powershell
   # Authenticates with Azure using Service Principal
   az login --service-principal
   ```

2. **ACR Login**
   ```powershell
   # Connects to Azure Container Registry
   az acr login --name msworkshopdevacr
   ```

3. **Image Building and Pushing**
   ```powershell
   # For each microservice:
   docker build -t servicename:latest ./microservices/servicename
   docker tag servicename:latest msworkshopdevacr.azurecr.io/servicename:latest
   docker push msworkshopdevacr.azurecr.io/servicename:latest
   ```

#### Microservices Built
| Service | Language/Framework | Purpose |
|---------|-------------------|---------|
| **auth-api** | Go | Authentication and JWT token generation |
| **users-api** | Java/Spring Boot | User profile management |
| **todos-api** | Node.js | TODO CRUD operations |
| **frontend** | Vue.js | User interface |
| **log-message-processor** | Python | Queue message processing |

#### Usage
```powershell
# Build and push all microservice images
.\scripts\deploy-acr.ps1
```

---

### 3. Kubernetes Deployment (`deploy-kub.ps1`)

**Purpose**: Deploys all microservices to the AKS cluster using Kubernetes manifests.

#### Process Flow

1. **Azure Authentication & Cluster Access**
   ```powershell
   # Login and get AKS credentials
   az login --service-principal
   az aks get-credentials --resource-group msworkshop-dev-rg --name msworkshop-dev-aks
   ```

2. **Application Deployment**
   ```powershell
   # Deploy using Kustomize
   kubectl apply -k deployment/kubernetes/dev/
   ```

3. **Health Verification**
   ```powershell
   # Wait for all pods to be Running
   kubectl get pods --no-headers
   # Verify pod readiness and status
   ```

4. **Rolling Restart**
   ```powershell
   # Ensure fresh deployment of all services
   kubectl rollout restart deployment [all-services]
   ```

#### Deployed Components
- **Microservices**: All 5 application services
- **Supporting Services**: Redis, Zipkin for tracing
- **Networking**: Services, Ingress controllers
- **Storage**: Persistent volumes where needed

#### Usage
```powershell
# Deploy all services to Kubernetes
.\scripts\deploy-kub.ps1
```

---

## Complete Deployment Workflow

### Step-by-Step Execution

```powershell
# 1. Deploy infrastructure (first time only)
.\scripts\deploy-infra.ps1 -Deploy all

# 2. Build and push container images
.\scripts\deploy-acr.ps1

# 3. Deploy applications to Kubernetes
.\scripts\deploy-kub.ps1
```

### Deployment Architecture Flow

```
[deploy-infra.ps1] → Azure Infrastructure (AKS + ACR)
         ↓
[deploy-acr.ps1]   → Container Images → ACR
         ↓
[deploy-kub.ps1]   → Kubernetes Deployments → AKS
```

## Verification Steps

### After Infrastructure Deployment
```powershell
# Verify AKS cluster
az aks show --resource-group msworkshop-dev-rg --name msworkshop-dev-aks

# Verify ACR
az acr show --name msworkshopdevacr
```

### After Image Deployment
```powershell
# List images in ACR
az acr repository list --name msworkshopdevacr
```

### After Kubernetes Deployment
```powershell
# Check all pods are running
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments
```

## Configuration Management

### Environment Variables
All scripts use consistent environment variables:
```powershell
$env:AZURE_CLIENT_ID = "ea9c5569-68db-48c8-b932-1041f724b986"
$env:AZURE_CLIENT_SECRET = "[SECRET]"
$env:AZURE_TENANT_ID = "e994072b-523e-4bfe-86e2-442c5e10b244"
$env:AZURE_SUBSCRIPTION_ID = "f3232678-472a-4a87-b56e-c8cbfa96666e"
```

### Resource Names
- **Resource Group**: `msworkshop-dev-rg`
- **AKS Cluster**: `msworkshop-dev-aks`
- **ACR**: `msworkshopdevacr`

## Troubleshooting

### Common Issues

#### Terraform State Lock
```powershell
# If terraform apply fails with state lock
terraform force-unlock [LOCK_ID]
```

#### Docker Build Failures
```powershell
# Check Docker daemon is running
docker version

# Clean up failed builds
docker system prune -f
```

#### Kubernetes Deployment Issues
```powershell
# Check pod logs
kubectl logs [pod-name]

# Describe problematic resources
kubectl describe pod [pod-name]
```

### Error Recovery

#### Re-run Specific Phases
```powershell
# Re-run only failed phase
.\scripts\deploy-infra.ps1 -Deploy bootstrap  # or dev
```

#### Clean Deployment
```powershell
# Delete and recreate deployments
kubectl delete -k deployment/kubernetes/dev/
.\scripts\deploy-kub.ps1
```

## Best Practices

### 1. **Sequential Execution**
Always run scripts in order: `deploy-infra` → `deploy-acr` → `deploy-kub`

### 2. **State Management**
- Keep Terraform state files secure
- Use remote state for team collaboration

### 3. **Version Control**
- Tag container images with version numbers
- Use semantic versioning for releases

### 4. **Monitoring**
- Verify each phase completion before proceeding
- Check logs for any warnings or errors

### 5. **Cleanup**
```powershell
# Clean up resources when no longer needed
terraform destroy -var="subscription_id=$subscriptionId"
```

This deployment process ensures a reliable, repeatable infrastructure setup for the microservices application with proper separation of concerns and error handling at each phase.