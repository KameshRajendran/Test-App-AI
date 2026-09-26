# Harness CI/CD Setup for React Application

## Overview

This directory contains the complete Harness CI/CD pipeline configuration for the React application. The pipeline includes:

- **Build & Test Stage**: Dependency installation, linting, testing, and building
- **Code Quality Gates**: Dependency scanning, coverage checks, bundle size analysis
- **Artifact Storage**: Build artifact management
- **Staging Deployment**: With manual approval gates and health checks
- **Smoke Tests**: Automated testing on staging environment
- **Production Deployment**: With strict approval requirements and blue-green deployment strategy

## Directory Structure

```
.harness/
├── pipeline.yaml              # Main CI/CD pipeline definition
├── services/
│   └── react-app-service.yaml # Service definition for React app
├── environments/
│   ├── staging.yaml          # Staging environment config
│   └── production.yaml        # Production environment config
└── README.md                 # This file
```

## Pipeline Stages

### 1. Build & Test Stage
**Runs on**: Every push and pull request

**Steps**:
- Install dependencies using npm
- Run ESLint for code quality
- Execute unit tests with coverage reporting
- Build React application

**Reports**: JUnit test reports, coverage metrics

### 2. Code Quality Gates
**Gate Type**: Custom validation stage

**Checks**:
- **Dependency Scan**: Scans for vulnerable npm packages
- **Code Coverage**: Ensures minimum 60% code coverage
- **Bundle Size**: Analyzes production bundle size

**Failure Handling**: Warnings are reported but don't block the pipeline

### 3. Artifact Storage
**Purpose**: Prepare and store build artifacts

### 4. Staging Deployment Gate
**Gate Type**: Manual approval

**Requirements**:
- Minimum 1 approver from `dev_team` user group
- Approval reason (required input)
- Tested by information (required input)
- Approval timeout: 1 day

### 5. Deploy to Staging
**Environment**: Staging

**Steps**:
- Apply Kubernetes manifests
- Run health checks
- Verify service availability

**Infrastructure**: Staging Kubernetes cluster

### 6. Smoke Tests (Staging)
**Purpose**: Run automated smoke tests against staging deployment

### 7. Production Deployment Gate
**Gate Type**: Manual approval

**Requirements**:
- Minimum 2 approvers from `release_managers` user group
- All approvers must be different from previous approvals
- Deployment reason (required)
- Rollback plan (required)
- Tested by information (required)
- Approval timeout: 7 days

### 8. Deploy to Production
**Environment**: Production

**Deployment Strategy**: Blue-Green deployment

**Steps**:
- Deploy using blue-green strategy
- Run health checks
- Verify production service availability

**Infrastructure**: Production Kubernetes cluster

## Configuration Files

### pipeline.yaml
Main pipeline orchestration file containing:
- Triggers (GitHub push and pull request)
- All pipeline stages
- Variables for staging and production URLs
- Docker registry configuration

### services/react-app-service.yaml
Service definition including:
- Docker image repository
- Kubernetes manifests location
- Service variables (app name, port, replicas)

### environments/staging.yaml & production.yaml
Environment configurations with:
- Resource limits and requests
- API endpoints
- Kubernetes cluster connections
- Variable overrides per environment

## Variables

### Pipeline Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `staging_url` | https://staging.app.example.com | Staging environment URL |
| `production_url` | https://app.example.com | Production environment URL |
| `docker_registry` | docker.io | Docker registry |
| `app_name` | react-app | Application name |

### Staging Environment Variables
| Variable | Value | Description |
|----------|-------|-------------|
| `replicas` | 2 | Number of pod replicas |
| `resource_cpu` | 250m | CPU request per pod |
| `resource_memory` | 512Mi | Memory request per pod |
| `log_level` | INFO | Application log level |
| `api_endpoint` | https://api-staging.example.com | API endpoint URL |

### Production Environment Variables
| Variable | Value | Description |
|----------|-------|-------------|
| `replicas` | 5 | Number of pod replicas |
| `resource_cpu` | 500m | CPU request per pod |
| `resource_memory` | 1Gi | Memory request per pod |
| `log_level` | WARN | Application log level |
| `api_endpoint` | https://api.example.com | API endpoint URL |

## Setup Instructions

### 1. Prerequisites
- Harness account with appropriate project
- GitHub repository connection (webhook)
- Kubernetes clusters for staging and production
- Docker registry credentials

### 2. Create Required Connectors in Harness UI

#### GitHub Connector
```
Name: github_connector
Type: GitHub
Authentication: Personal Access Token or OAuth
```

#### Docker Hub Connector
```
Name: docker_hub_connector
Type: DockerRegistry
URL: https://index.docker.io/v2/
Authentication: Username/Password or Docker Config JSON
```

#### Kubernetes Connectors
```
Staging Cluster:
  Name: staging_k8s_connector
  Type: Kubernetes
  URL: <staging-cluster-api-endpoint>
  
Production Cluster:
  Name: prod_k8s_connector
  Type: Kubernetes
  URL: <production-cluster-api-endpoint>
```

### 3. Create User Groups
```
dev_team
- Development team members for staging approvals

release_managers
- Release managers for production approvals (minimum 2)
```

### 4. Import Pipeline
1. In Harness UI, navigate to your project
2. Go to Pipelines → New Pipeline
3. Select "YAML" and copy content from `pipeline.yaml`
4. Update variables with your actual URLs and credentials
5. Save and trigger manually or wait for GitHub webhook

### 5. Configure Triggers
- **On Push to Main**: Automatically triggers pipeline
- **On Pull Request**: Triggers for PR verification

## Testing the Pipeline Locally

### Prerequisites
```bash
npm install
```

### Run Linting
```bash
npm run lint
```

### Run Tests
```bash
npm test -- --coverage --watchAll=false
```

### Build
```bash
npm run build
```

### Dependency Check
```bash
npm audit --production
```

## Kubernetes Manifests

### Base Manifests (k8s/base/)
- `deployment.yaml`: Main deployment configuration
- `service.yaml`: Kubernetes Service definition
- `ingress.yaml`: Ingress configuration for external access

### Environment-Specific Manifests
- `k8s/staging/deployment.yaml`: Staging deployment with 2 replicas
- `k8s/production/deployment.yaml`: Production deployment with 5 replicas

## Docker Image Building

### Build Locally
```bash
docker build -t react-app:v1.0 .
```

### Multi-Stage Build
- **Builder stage**: Installs dependencies and builds React app
- **Runtime stage**: Minimal image with only necessary files

### Image Features
- Alpine Linux base for small footprint
- Non-root user (appuser) for security
- Health checks configured
- Environment variables support

## Deployment Strategies

### Staging
- Rolling update strategy
- Max surge: 1, Max unavailable: 0

### Production
- Blue-Green deployment
- Automatic pruning of old deployments
- Pod anti-affinity for distribution

## Health Checks

### Liveness Probe
- Path: `/health`
- Initial delay: 30 seconds
- Period: 10 seconds
- Failure threshold: 3

### Readiness Probe
- Path: `/ready`
- Initial delay: 10 seconds
- Period: 5 seconds
- Failure threshold: 2

## Gates and Approvals

### Quality Gates (Automatic)
1. Dependency vulnerability scan
2. Code coverage check (minimum 60%)
3. Bundle size analysis

### Staging Approval Gate
- Required: 1 approver from dev_team
- Input: deployment reason, tested by
- Timeout: 1 day

### Production Approval Gate
- Required: 2 different approvers from release_managers
- Input: deployment reason, rollback plan, tested by
- Timeout: 7 days

## Rollback Procedures

### Manual Rollback in Harness
1. Navigate to deployment execution
2. Click "Rollback"
3. Select previous stable version
4. Confirm rollback

### Kubernetes Native Rollback
```bash
kubectl rollout undo deployment/react-app -n production
```

## Monitoring and Logs

### Access Pipeline Logs
1. Harness UI → Pipeline → Execution History
2. Click execution → View logs
3. Filter by stage or step

### Kubernetes Pod Logs
```bash
kubectl logs -l app=react-app -n production
```

## Troubleshooting

### Pipeline Failures

#### Build Fails
- Check npm version compatibility
- Verify Node.js version (18.x recommended)
- Run `npm install` locally to reproduce

#### Deployment Fails
- Verify Kubernetes cluster connectivity
- Check cluster resource availability
- Review security policies and RBAC

#### Health Check Fails
- Verify `/health` endpoint is implemented
- Check service port configuration
- Review application startup time

### Approval Gate Issues

#### Approvers Not Available
- Verify user group membership in Harness
- Check approval timeout settings
- Review user permissions

## Best Practices

1. **Always require approval for production**
2. **Use environment-specific variables**
3. **Monitor deployment metrics**
4. **Maintain rollback capabilities**
5. **Test in staging before production**
6. **Review code coverage trends**
7. **Keep dependencies updated**
8. **Use non-root containers**
9. **Implement proper health checks**
10. **Monitor logs and metrics**

## Additional Resources

- [Harness Documentation](https://docs.harness.io)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Docker Documentation](https://docs.docker.com)
- [React Documentation](https://react.dev)

## Support

For issues or questions:
1. Check pipeline execution logs
2. Review Kubernetes cluster status
3. Verify connector configurations
4. Contact DevOps team

## Next Steps

1. Update URLs in pipeline variables
2. Create necessary Harness connectors
3. Configure user groups for approvals
4. Set up monitoring and alerting
5. Test pipeline with sample deployment
