# Harness Setup Guide for React Application

## Quick Start

This guide will help you set up Harness CI/CD for this React application in 15 minutes.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step-by-Step Setup](#step-by-step-setup)
3. [Configuration](#configuration)
4. [Verification](#verification)
5. [Common Issues](#common-issues)

## Prerequisites

- [ ] Harness account (SaaS or self-hosted)
- [ ] GitHub repository with webhook access
- [ ] Kubernetes clusters (staging and production)
- [ ] Docker registry (Docker Hub, ECR, GCR, etc.)
- [ ] Admin access to Harness project

## Step-by-Step Setup

### Step 1: Create Harness Project

1. Log in to Harness
2. Click **Projects** → **New Project**
3. Enter project name: `React-App`
4. Click **Save**
5. Note the **Project Identifier** (you'll need it later)

### Step 2: Create Connectors

#### 2.1 GitHub Connector

1. Go to **Project Settings** → **Connectors**
2. Click **New Connector** → **GitHub**
3. Configure:
   - **Name**: `github_connector`
   - **URL Type**: Repository
   - **Connection Type**: HTTP
   - **GitHub URL**: `https://github.com/your-org/your-repo`
   - **Authentication**: Personal Access Token (PAT)
     - Generate PAT with `repo` and `admin:repo_hook` scopes
     - Paste token in **GitHub Token** field
4. Click **Test Connection**
5. Click **Save**

#### 2.2 Docker Registry Connector

1. Go to **Connectors** → **New Connector** → **Docker Registry**
2. Configure:
   - **Name**: `docker_hub_connector`
   - **Provider**: Docker Hub (or your registry)
   - **Docker Registry URL**: `https://index.docker.io/v2/`
   - **Authentication**: Username/Password
     - **Username**: Your Docker Hub username
     - **Password**: Docker Hub personal access token
3. Click **Test Connection**
4. Click **Save**

#### 2.3 Kubernetes Connector - Staging

1. Go to **Connectors** → **New Connector** → **Kubernetes Cluster**
2. Configure:
   - **Name**: `staging_k8s_connector`
   - **Cluster Type**: Direct connection (or GKE/EKS/AKS)
   - **Kubernetes Master URL**: `https://<staging-cluster-api>:6443`
   - **Authentication**: Service Account Token
     - Create service account in staging cluster:
       ```bash
       kubectl create serviceaccount harness-delegate -n default
       kubectl create clusterrolebinding harness-admin --clusterrole=cluster-admin --serviceaccount=default:harness-delegate
       TOKEN=$(kubectl get secret $(kubectl get secret -n default | grep harness-delegate-token | awk '{print $1}') -n default -o jsonpath='{.data.token}' | base64 --decode)
       echo $TOKEN
       ```
     - Paste the token
3. Click **Test Connection**
4. Click **Save**

#### 2.4 Kubernetes Connector - Production

Repeat step 2.3 with:
- **Name**: `prod_k8s_connector`
- **Kubernetes Master URL**: `https://<production-cluster-api>:6443`

### Step 3: Create User Groups

#### 3.1 Dev Team Group

1. Go to **Access Control** → **User Groups**
2. Click **New User Group**
3. Configure:
   - **Name**: `dev_team`
   - **Description**: Development team members
   - **Members**: Add your dev team members
4. Click **Save**

#### 3.2 Release Managers Group

1. Click **New User Group**
2. Configure:
   - **Name**: `release_managers`
   - **Description**: Release managers for production deployments
   - **Members**: Add 2+ release managers
3. Click **Save**

### Step 4: Create Service and Environments

#### 4.1 Create Service

1. Go to **Services** → **New Service**
2. Configure:
   - **Name**: `React App Service`
   - **Identifier**: `react_app_service`
   - **Deployment Type**: Kubernetes
3. In **Service Definition**:
   - **Artifacts**: Connect to Docker registry connector
   - **Manifests**: Point to GitHub repository `/k8s/` directory
4. Click **Save**

#### 4.2 Create Staging Environment

1. Go to **Environments** → **New Environment**
2. Configure:
   - **Name**: `Staging`
   - **Identifier**: `staging`
   - **Type**: Production (or PreProduction)
   - **Infrastructure**: 
     - Click **Infrastructure** → **New Infrastructure**
     - **Name**: `staging_infra`
     - **Type**: Kubernetes Direct
     - **Connector**: `staging_k8s_connector`
     - **Namespace**: `default`
3. Add Variables:
   ```
   api_endpoint: https://api-staging.example.com
   environment_name: staging
   replicas: 2
   resource_cpu: 250m
   resource_memory: 512Mi
   log_level: INFO
   ```
4. Click **Save**

#### 4.3 Create Production Environment

1. Click **New Environment**
2. Configure:
   - **Name**: `Production`
   - **Identifier**: `production`
   - **Type**: Production
   - **Infrastructure**:
     - **Name**: `prod_infra`
     - **Type**: Kubernetes Direct
     - **Connector**: `prod_k8s_connector`
     - **Namespace**: `production`
3. Add Variables:
   ```
   api_endpoint: https://api.example.com
   environment_name: production
   replicas: 5
   resource_cpu: 500m
   resource_memory: 1Gi
   log_level: WARN
   ```
4. Click **Save**

### Step 5: Create the Pipeline

1. Go to **Pipelines** → **New Pipeline**
2. Enter **Name**: `React App CI/CD`
3. Select **YAML** option
4. Copy the entire content from `.harness/pipeline.yaml`
5. Update the following in the YAML:
   - Replace `DEFAULT_PROJECT` with your project identifier
   - Replace `default` with your organization identifier
   - Update `staging_url` and `production_url` values
6. Click **Save**

### Step 6: Set Up GitHub Webhook

1. Go to **Pipelines** → Select your pipeline
2. Click **Triggers**
3. For each trigger (On Push, On PR):
   - Click the trigger
   - Copy the **Webhook URL**
4. Go to GitHub repository:
   - Settings → Webhooks → Add webhook
   - **Payload URL**: Paste the webhook URL from Harness
   - **Content type**: `application/json`
   - **Events**: Select "Just the push event" or "Pull requests"
   - Check **Active**
   - Click **Add webhook**

### Step 7: Build Prerequisites in Repository

Ensure your React app has:

#### package.json Scripts
```json
{
  "scripts": {
    "lint": "eslint src/",
    "test": "jest",
    "coverage": "jest --coverage",
    "build": "react-scripts build"
  }
}
```

#### Health Check Endpoints
Add to your Express/Node server (if using one):
```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready' });
});
```

## Configuration

### Update Variables

Before first run, update these pipeline variables:

1. Go to **Pipelines** → Your pipeline → **Variables**
2. Update each variable:

| Variable | Update to |
|----------|-----------|
| `staging_url` | Your staging domain |
| `production_url` | Your production domain |
| `docker_registry` | Your Docker registry URL |
| `app_name` | Your app name |

### Configure Kubernetes Namespaces

Ensure these namespaces exist in your clusters:

**Staging Cluster**:
```bash
kubectl create namespace default
```

**Production Cluster**:
```bash
kubectl create namespace production
kubectl create namespace default  # for shared resources
```

### Create Kubernetes Secrets

For production deployments, create secrets in your clusters:

```bash
# Staging
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  -n default

# Production
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  -n production
```

## Verification

### Test the Pipeline

1. **Manual Trigger**:
   - Go to **Pipelines** → Your pipeline
   - Click **Run**
   - Select branch: `main`
   - Click **Run Pipeline**

2. **Watch Execution**:
   - Monitor Build & Test stage
   - Check test results
   - Verify artifact creation

3. **Approve Staging Deployment**:
   - Pipeline will pause at approval gate
   - Review the deployment details
   - Provide approval reason
   - Click **Approve**

4. **Monitor Staging Deployment**:
   - Watch deployment progress
   - Verify health checks pass
   - Check pod readiness

5. **Approve Production (Optional)**:
   - If you reach production approval gate
   - Have 2+ managers approve
   - Each must provide required inputs

### Verify in Kubernetes

```bash
# Check staging deployment
kubectl get deployment -n default
kubectl get pods -l app=react-app -n default
kubectl logs -l app=react-app -n default

# Check production deployment
kubectl get deployment -n production
kubectl get pods -l app=react-app -n production
kubectl logs -l app=react-app -n production
```

### Verify Service Accessibility

```bash
# Port forward to test locally
kubectl port-forward -n default svc/react-app 3000:80

# Then access
curl http://localhost:3000/health
curl http://localhost:3000
```

## Common Issues

### Issue 1: Connector Test Fails

**Symptom**: "Connection failed" when testing connector

**Solutions**:
1. Verify credentials are correct
2. Check network connectivity
3. For Kubernetes: Ensure API server is accessible
4. For Docker: Verify registry URL format

### Issue 2: Pod Fails to Start

**Symptom**: Pods stuck in `ImagePullBackOff` or `CrashLoopBackOff`

**Debug**:
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

**Solutions**:
1. Verify Docker image exists in registry
2. Check image pull secrets
3. Verify resource limits aren't too restrictive
4. Check application startup logs

### Issue 3: Health Check Fails

**Symptom**: Pods killed due to liveness/readiness probe failures

**Solutions**:
1. Verify `/health` and `/ready` endpoints exist
2. Increase `initialDelaySeconds` in deployment
3. Check application startup time
4. Verify port number matches (3000)

### Issue 4: Approval Timeout

**Symptom**: "Pipeline auto-rejected due to approval timeout"

**Solutions**:
1. Ensure approvers have Harness access
2. Check user group membership
3. Configure Slack/email notifications for approvals
4. Increase timeout if needed

### Issue 5: Resource Constraints

**Symptom**: Pod scheduling failures or resource limits exceeded

**Solutions**:
1. Check cluster resource availability: `kubectl top nodes`
2. Increase resource requests/limits in deployment
3. Check storage availability
4. Consider cluster scaling

## Next Steps

1. Configure monitoring and logging (DataDog, New Relic, etc.)
2. Set up notifications (Slack, Email, PagerDuty)
3. Configure advanced gates (SonarQube, Snyk)
4. Document runbooks for common failures
5. Train team on deployment procedures
6. Set up cost tracking and optimization

## Support Resources

- [Harness Documentation](https://docs.harness.io)
- [Harness Community](https://community.harness.io)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster)
- [Docker Documentation](https://docs.docker.com)

## Rollback Checklist

If deployment goes wrong:

- [ ] Click **Rollback** in pipeline execution
- [ ] Select previous stable version
- [ ] Confirm rollback
- [ ] Monitor logs during rollback
- [ ] Verify service is healthy after rollback
- [ ] Post-mortem on what went wrong

---

**Setup Complete!** Your React application is now ready for Harness CI/CD deployments.
