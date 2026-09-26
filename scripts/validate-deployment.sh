#!/bin/bash

# Deployment Validation Script for React Application
# This script validates the deployment before and after release

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-staging}
NAMESPACE=${2:-default}
APP_NAME="react-app"
TIMEOUT=300  # 5 minutes

echo -e "${BLUE}=== React App Deployment Validation ===${NC}"
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo ""

# ==================== PRE-DEPLOYMENT CHECKS ====================
echo -e "${BLUE}[1/5] Pre-Deployment Checks${NC}"

# Check kubectl connectivity
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo -e "${RED}✗ Kubernetes cluster not accessible${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Kubernetes cluster accessible${NC}"

# Check namespace exists
if ! kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Namespace '$NAMESPACE' does not exist, creating...${NC}"
    kubectl create namespace "$NAMESPACE"
else
    echo -e "${GREEN}✓ Namespace '$NAMESPACE' exists${NC}"
fi

# ==================== DEPLOYMENT CHECK ====================
echo -e "\n${BLUE}[2/5] Deployment Status${NC}"

# Check if deployment exists
if ! kubectl get deployment "$APP_NAME" -n "$NAMESPACE" > /dev/null 2>&1; then
    echo -e "${RED}✗ Deployment '$APP_NAME' not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Deployment exists${NC}"

# Get deployment status
READY_REPLICAS=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

echo "Ready Replicas: $READY_REPLICAS / $DESIRED_REPLICAS"

if [ "$READY_REPLICAS" != "$DESIRED_REPLICAS" ]; then
    echo -e "${YELLOW}⚠ Not all replicas are ready${NC}"
    echo "Waiting for replicas to be ready..."
    
    ELAPSED=0
    while [ "$READY_REPLICAS" != "$DESIRED_REPLICAS" ] && [ $ELAPSED -lt $TIMEOUT ]; do
        sleep 10
        ELAPSED=$((ELAPSED + 10))
        READY_REPLICAS=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        echo "  Status: $READY_REPLICAS / $DESIRED_REPLICAS (elapsed: ${ELAPSED}s)"
    done
fi

if [ "$READY_REPLICAS" = "$DESIRED_REPLICAS" ]; then
    echo -e "${GREEN}✓ All replicas are ready${NC}"
else
    echo -e "${RED}✗ Deployment replicas not ready after timeout${NC}"
    exit 1
fi

# ==================== POD CHECK ====================
echo -e "\n${BLUE}[3/5] Pod Status${NC}"

# Get pod list
PODS=$(kubectl get pods -n "$NAMESPACE" -l app="$APP_NAME" -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
    echo -e "${RED}✗ No pods found for app '$APP_NAME'${NC}"
    exit 1
fi

FAILED_PODS=0
for POD in $PODS; do
    POD_STATUS=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    
    if [ "$POD_STATUS" = "Running" ]; then
        # Check if pod is ready
        READY=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$READY" = "True" ]; then
            echo -e "${GREEN}✓ Pod $POD is running and ready${NC}"
        else
            echo -e "${YELLOW}⚠ Pod $POD is running but not ready${NC}"
        fi
    else
        echo -e "${RED}✗ Pod $POD status: $POD_STATUS${NC}"
        FAILED_PODS=$((FAILED_PODS + 1))
    fi
done

if [ $FAILED_PODS -gt 0 ]; then
    echo -e "${RED}✗ $FAILED_PODS pods are not in running state${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All pods are running${NC}"

# ==================== HEALTH CHECK ====================
echo -e "\n${BLUE}[4/5] Health Checks${NC}"

# Get service endpoint
SERVICE_IP=$(kubectl get svc "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

if [ -z "$SERVICE_IP" ]; then
    echo -e "${YELLOW}⚠ Service not found, using pod port-forward${NC}"
    
    # Get first pod
    FIRST_POD=$(echo $PODS | awk '{print $1}')
    
    # Port forward in background
    kubectl port-forward "pod/$FIRST_POD" 3000:3000 -n "$NAMESPACE" > /dev/null 2>&1 &
    PORT_FORWARD_PID=$!
    sleep 2
    
    SERVICE_IP="127.0.0.1"
    SERVICE_PORT="3000"
else
    SERVICE_PORT=$(kubectl get svc "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
fi

# Check health endpoint
MAX_RETRIES=5
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${SERVICE_IP}:${SERVICE_PORT}/health" 2>/dev/null || echo "000")
    
    if [ "$HEALTH_STATUS" = "200" ]; then
        echo -e "${GREEN}✓ Health check passed (HTTP $HEALTH_STATUS)${NC}"
        break
    else
        echo -e "${YELLOW}⚠ Health check returned HTTP $HEALTH_STATUS, retrying...${NC}"
        RETRY=$((RETRY + 1))
        sleep 5
    fi
done

if [ "$HEALTH_STATUS" != "200" ]; then
    echo -e "${RED}✗ Health check failed${NC}"
    # Don't exit on health check failure in staging
    if [ "$ENVIRONMENT" = "production" ]; then
        exit 1
    fi
fi

# Check readiness endpoint
READY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://${SERVICE_IP}:${SERVICE_PORT}/ready" 2>/dev/null || echo "000")

if [ "$READY_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Readiness check passed (HTTP $READY_STATUS)${NC}"
else
    echo -e "${YELLOW}⚠ Readiness check returned HTTP $READY_STATUS${NC}"
fi

# Cleanup port-forward if we created it
if [ ! -z "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID 2>/dev/null || true
fi

# ==================== RESOURCE CHECK ====================
echo -e "\n${BLUE}[5/5] Resource Utilization${NC}"

# Get resource usage
echo "Checking pod resource usage..."

for POD in $PODS; do
    # Get metrics if metrics-server is available
    if kubectl top pod "$POD" -n "$NAMESPACE" > /dev/null 2>&1; then
        METRICS=$(kubectl top pod "$POD" -n "$NAMESPACE" | tail -1)
        echo -e "${GREEN}✓ $POD: $METRICS${NC}"
    fi
done

# ==================== SUMMARY ====================
echo -e "\n${BLUE}=== Deployment Validation Summary ===${NC}"

if [ $FAILED_PODS -eq 0 ] && [ "$HEALTH_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ All checks passed! Deployment is healthy.${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some checks may need attention${NC}"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        exit 1
    else
        exit 0
    fi
fi
