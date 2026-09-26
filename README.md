# React App with Harness CI/CD

A modern React application with complete Harness CI/CD pipeline setup, including quality gates, approval workflows, and multi-environment deployments.

## Features

- ✅ **Complete CI/CD Pipeline**: Build, test, quality gates, and deployment automation
- ✅ **Quality Gates**: Dependency scanning, code coverage checks, bundle size analysis
- ✅ **Approval Workflows**: Staging and production approval gates with audit trails
- ✅ **Multi-Environment**: Separate staging and production configurations
- ✅ **Kubernetes Deployment**: K8s manifests for both environments
- ✅ **Docker Support**: Multi-stage Dockerfile for optimized images
- ✅ **Health Checks**: Liveness and readiness probes configured
- ✅ **Blue-Green Deployment**: Zero-downtime deployment strategy for production
- ✅ **Automated Testing**: Unit tests, linting, and smoke tests
- ✅ **Security**: Non-root containers, security scanning, RBAC support

## Quick Start

### Prerequisites
- Node.js 18+ 
- Docker (for containerization)
- Kubernetes cluster(s) (staging + production)
- Harness account

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm start

# Run tests
npm test

# Run linting
npm run lint

# Build for production
npm run build
```

### Harness Setup

1. **Read the setup guide**:
   ```bash
   cat HARNESS_SETUP_GUIDE.md
   ```

2. **Quick setup (15 minutes)**:
   - Create Harness project
   - Configure connectors (GitHub, Docker, Kubernetes)
   - Create user groups (dev_team, release_managers)
   - Import pipeline from `.harness/pipeline.yaml`
   - Set up GitHub webhook

3. **Detailed documentation**:
   - See `.harness/README.md` for complete pipeline documentation
   - See `.harness/gates-configuration.yaml` for all quality gates
   - See `HARNESS_SETUP_GUIDE.md` for step-by-step instructions

## Project Structure

```
.
├── .harness/                          # Harness CI/CD configuration
│   ├── pipeline.yaml                  # Main pipeline definition
│   ├── services/
│   │   └── react-app-service.yaml    # Service definition
│   ├── environments/
│   │   ├── staging.yaml              # Staging environment config
│   │   └── production.yaml            # Production environment config
│   ├── gates-configuration.yaml       # Quality gates documentation
│   └── README.md                      # Detailed pipeline documentation
├── k8s/                               # Kubernetes manifests
│   ├── base/                          # Base configurations
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── staging/
│   │   └── deployment.yaml            # Staging-specific deployment
│   └── production/
│       └── deployment.yaml            # Production-specific deployment
├── scripts/
│   └── validate-deployment.sh         # Deployment validation script
├── src/                               # React source code
├── public/                            # Static assets
├── Dockerfile                         # Multi-stage Docker build
├── package.json                       # Dependencies and scripts
├── .env.example                       # Environment variables template
└── HARNESS_SETUP_GUIDE.md            # Complete setup guide
```

## Pipeline Stages

### 1. **Build & Test**
- Install dependencies
- Run linting checks
- Execute unit tests with coverage
- Build production bundle

### 2. **Code Quality Gates**
- Dependency vulnerability scanning
- Code coverage validation
- Bundle size analysis

### 3. **Staging Deployment**
- Manual approval (1 approver from dev_team)
- Deploy to staging K8s cluster
- Health checks and readiness verification
- Smoke test execution

### 4. **Production Deployment**
- Manual approval (2 approvers from release_managers)
- Blue-green deployment strategy
- Health checks and verification
- Automatic rollback on failure

## Quality Gates

### Automated Checks
| Gate | Threshold | Tool |
|------|-----------|------|
| Dependency Scan | High severity | npm audit |
| Code Coverage | 60% minimum | Jest |
| Bundle Size | 500KB maximum | Webpack |

### Approval Gates
| Environment | Required Approvers | Timeout | Inputs |
|-------------|-------------------|---------|--------|
| Staging | 1 from dev_team | 24 hours | Reason, Tested by |
| Production | 2 from release_managers | 7 days | Reason, Rollback plan, Tested by |

## Deployment Strategies

### Staging
- Rolling update
- 2 replicas
- Request: 250m CPU, 512Mi memory
- Limit: 500m CPU, 1Gi memory

### Production
- Blue-Green deployment
- 5 replicas
- Request: 500m CPU, 1Gi memory
- Limit: 1000m CPU, 2Gi memory
- Pod anti-affinity for distribution

## Environment Configuration

### Variables

**Staging**:
- API: https://api-staging.example.com
- Replicas: 2
- Log Level: INFO

**Production**:
- API: https://api.example.com
- Replicas: 5
- Log Level: WARN

See `.harness/environments/*.yaml` for complete configuration.

## Docker

### Build
```bash
docker build -t react-app:v1.0 .
```

### Run
```bash
docker run -p 3000:80 react-app:v1.0
```

### Features
- Multi-stage build (optimized final image)
- Non-root user execution
- Health checks configured
- Alpine Linux base

## Kubernetes Deployment

### Deploy to Staging
```bash
kubectl apply -f k8s/staging/deployment.yaml -n default
```

### Deploy to Production
```bash
kubectl apply -f k8s/production/deployment.yaml -n production
```

### Health Checks
- **Liveness**: `/health` - HTTP 200
- **Readiness**: `/ready` - HTTP 200

### Validate Deployment
```bash
scripts/validate-deployment.sh staging default
scripts/validate-deployment.sh production production
```

## API Endpoints

Your application should implement these health check endpoints:

```javascript
// health.js
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready' });
});
```

## Troubleshooting

### Build Failures
1. Check Node.js version: `node --version` (18+ required)
2. Clear cache: `npm cache clean --force`
3. Reinstall: `rm -rf node_modules && npm install`

### Deployment Issues
1. Check pod logs: `kubectl logs -l app=react-app -n <namespace>`
2. Describe pod: `kubectl describe pod <pod-name> -n <namespace>`
3. Check events: `kubectl get events -n <namespace>`

### Health Check Failures
1. Verify endpoints exist in application
2. Check port configuration (default: 3000)
3. Review application startup logs
4. Increase initialDelaySeconds if needed

### Approval Gate Timeouts
1. Check user group membership in Harness
2. Configure Slack/email notifications
3. Verify approver permissions
4. Consider increasing timeout duration

## Monitoring & Logging

### View Pipeline Logs
1. Go to Harness UI
2. Pipeline → Execution History
3. Click execution → View logs

### View Kubernetes Logs
```bash
# Real-time logs
kubectl logs -f -l app=react-app -n <namespace>

# All pod logs
kubectl logs --all-containers=true -l app=react-app -n <namespace>

# Previous container logs (for crashes)
kubectl logs <pod-name> -n <namespace> --previous
```

### Pod Metrics
```bash
kubectl top pods -l app=react-app -n <namespace>
kubectl top nodes
```

## Security

### Features Implemented
- ✅ Non-root container user
- ✅ Read-only root filesystem
- ✅ Security scanning in pipeline
- ✅ Dependency vulnerability checks
- ✅ RBAC support
- ✅ Network policies ready
- ✅ Secret management support

### Best Practices
1. Never commit `.env` files with secrets
2. Use Kubernetes secrets for sensitive data
3. Rotate credentials regularly
4. Review security scan results
5. Keep dependencies updated
6. Use private Docker registries

## Performance

### Optimization Tips
1. **Bundle Size**: Analyze with `npm run build`
2. **Coverage**: Check test coverage gaps
3. **Build Time**: Monitor CI pipeline duration
4. **Pod Startup**: Review liveness probe delays

### Metrics
- Build time: Target < 5 minutes
- Bundle size: Target < 500KB
- Code coverage: Target > 60%
- Deployment time: Target < 10 minutes

## Contributing

1. Create feature branch from `main`
2. Make changes and commit with clear messages
3. Push to feature branch
4. Create pull request
5. Pipeline runs automatically (build, test, quality checks)
6. Request review from team leads
7. Approve and merge to `main`
8. Pipeline triggers deployment

## Documentation

### Read First
- `HARNESS_SETUP_GUIDE.md` - Complete setup instructions
- `.harness/README.md` - Pipeline documentation
- `.harness/gates-configuration.yaml` - Gates documentation

### Additional Resources
- [Harness Docs](https://docs.harness.io)
- [Kubernetes Docs](https://kubernetes.io/docs)
- [Docker Docs](https://docs.docker.com)
- [React Docs](https://react.dev)

## Support

### For Setup Help
1. Check `HARNESS_SETUP_GUIDE.md`
2. Review `.harness/README.md`
3. Check troubleshooting section
4. Contact DevOps team

### For Deployment Issues
1. Review pipeline logs
2. Check Kubernetes pod status
3. Verify health endpoints
4. Review resource limits

## Rollback

### Via Harness
1. Pipeline → Execution History
2. Click execution → Rollback
3. Select previous stable version
4. Confirm rollback

### Via Kubernetes
```bash
# Check rollout history
kubectl rollout history deployment/react-app -n production

# Rollback to previous version
kubectl rollout undo deployment/react-app -n production

# Rollback to specific version
kubectl rollout undo deployment/react-app -n production --to-revision=2
```

## License

MIT

## Contact

For questions or issues, contact the DevOps team or check the documentation.