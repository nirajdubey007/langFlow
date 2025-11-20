# CI/CD Pipeline Integration Guide

This guide shows how to integrate Langflow deployment with your CI/CD pipeline.

## 🔄 Automated Deployment Flow

```
Code Push → Build Docker Image → Push to Registry → Update K8s Deployment
```

## 📦 GitHub Actions Example

Create `.github/workflows/deploy-langflow.yml`:

```yaml
name: Build and Deploy Langflow

on:
  push:
    branches:
      - main
      - develop
  workflow_dispatch:

env:
  DOCKER_IMAGE: cera123/langflow
  NAMESPACE: prod

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.tag.outputs.tag }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Generate image tag
        id: tag
        run: |
          SHORT_SHA=$(git rev-parse --short HEAD)
          TAG="${SHORT_SHA}-$(date +%Y%m%d-%H%M%S)"
          echo "tag=$TAG" >> $GITHUB_OUTPUT
          echo "Image tag: $TAG"

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ${{ env.DOCKER_IMAGE }}:${{ steps.tag.outputs.tag }}
            ${{ env.DOCKER_IMAGE }}:latest
          cache-from: type=registry,ref=${{ env.DOCKER_IMAGE }}:latest
          cache-to: type=inline

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'latest'

      - name: Configure Kubernetes context
        env:
          KUBECONFIG_CONTENT: ${{ secrets.KUBECONFIG }}
        run: |
          mkdir -p ~/.kube
          echo "$KUBECONFIG_CONTENT" | base64 -d > ~/.kube/config
          chmod 600 ~/.kube/config

      - name: Verify cluster connection
        run: |
          kubectl cluster-info
          kubectl get nodes

      - name: Update deployment image
        run: |
          kubectl set image deployment/langflow-api-prod \
            langflow-api-prod-image=${{ env.DOCKER_IMAGE }}:${{ needs.build-and-push.outputs.image_tag }} \
            -n ${{ env.NAMESPACE }}

      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/langflow-api-prod -n ${{ env.NAMESPACE }} --timeout=5m

      - name: Verify deployment
        run: |
          kubectl get pods -n ${{ env.NAMESPACE }} -l app=langflow-api-prod
          
      - name: Check health
        run: |
          sleep 10
          POD=$(kubectl get pod -n ${{ env.NAMESPACE }} -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')
          kubectl exec -n ${{ env.NAMESPACE }} $POD -- curl -f http://localhost:7860/health

      - name: Rollback on failure
        if: failure()
        run: |
          echo "Deployment failed, rolling back..."
          kubectl rollout undo deployment/langflow-api-prod -n ${{ env.NAMESPACE }}
```

### Required GitHub Secrets

Add these to your GitHub repository settings:

1. **DOCKER_USERNAME** - Your Docker Hub username
2. **DOCKER_PASSWORD** - Your Docker Hub password or access token
3. **KUBECONFIG** - Your base64 encoded kubeconfig file

```bash
# Generate KUBECONFIG secret
cat ~/.kube/config | base64 -w 0
# Copy the output and add as GitHub secret
```

## 🦊 GitLab CI/CD Example

Create `.gitlab-ci.yml`:

```yaml
stages:
  - build
  - deploy

variables:
  DOCKER_IMAGE: cera123/langflow
  NAMESPACE: prod
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
  script:
    - export IMAGE_TAG="${CI_COMMIT_SHORT_SHA}-$(date +%Y%m%d-%H%M%S)"
    - echo "Building image with tag $IMAGE_TAG"
    - docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
    - docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest
    - docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
    - docker push ${DOCKER_IMAGE}:latest
    - echo "IMAGE_TAG=${IMAGE_TAG}" > build.env
  artifacts:
    reports:
      dotenv: build.env
  only:
    - main
    - develop

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  before_script:
    - mkdir -p ~/.kube
    - echo "$KUBECONFIG_CONTENT" | base64 -d > ~/.kube/config
    - chmod 600 ~/.kube/config
  script:
    - kubectl cluster-info
    - kubectl get nodes
    - |
      kubectl set image deployment/langflow-api-prod \
        langflow-api-prod-image=${DOCKER_IMAGE}:${IMAGE_TAG} \
        -n ${NAMESPACE}
    - kubectl rollout status deployment/langflow-api-prod -n ${NAMESPACE} --timeout=5m
    - kubectl get pods -n ${NAMESPACE} -l app=langflow-api-prod
  only:
    - main
    - develop
  when: on_success
```

### Required GitLab CI/CD Variables

Add these in GitLab Settings → CI/CD → Variables:

1. **DOCKER_USERNAME** - Docker Hub username
2. **DOCKER_PASSWORD** - Docker Hub password
3. **KUBECONFIG_CONTENT** - Base64 encoded kubeconfig

## 🔵 Azure DevOps Pipeline Example

Create `azure-pipelines.yml`:

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  dockerImage: 'cera123/langflow'
  namespace: 'prod'

stages:
- stage: Build
  displayName: 'Build and Push Docker Image'
  jobs:
  - job: Build
    displayName: 'Build Job'
    steps:
    - task: Docker@2
      displayName: 'Login to Docker Hub'
      inputs:
        command: login
        containerRegistry: 'DockerHub'

    - task: Bash@3
      displayName: 'Generate Image Tag'
      inputs:
        targetType: 'inline'
        script: |
          SHORT_SHA=$(git rev-parse --short HEAD)
          TAG="${SHORT_SHA}-$(date +%Y%m%d-%H%M%S)"
          echo "##vso[task.setvariable variable=imageTag;isOutput=true]$TAG"
          echo "Image tag: $TAG"
      name: tagStep

    - task: Docker@2
      displayName: 'Build and Push'
      inputs:
        command: buildAndPush
        repository: $(dockerImage)
        dockerfile: 'Dockerfile'
        tags: |
          $(tagStep.imageTag)
          latest

- stage: Deploy
  displayName: 'Deploy to Kubernetes'
  dependsOn: Build
  variables:
    imageTag: $[ stageDependencies.Build.Build.outputs['tagStep.imageTag'] ]
  jobs:
  - deployment: Deploy
    displayName: 'Deploy Job'
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: Kubernetes@1
            displayName: 'kubectl set image'
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceEndpoint: 'k8s-cluster'
              namespace: '$(namespace)'
              command: 'set'
              arguments: 'image deployment/langflow-api-prod langflow-api-prod-image=$(dockerImage):$(imageTag)'

          - task: Kubernetes@1
            displayName: 'kubectl rollout status'
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceEndpoint: 'k8s-cluster'
              namespace: '$(namespace)'
              command: 'rollout'
              arguments: 'status deployment/langflow-api-prod --timeout=5m'
```

## 🐋 Jenkins Pipeline Example

Create `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'cera123/langflow'
        NAMESPACE = 'prod'
        DOCKER_CREDENTIALS = credentials('docker-hub-credentials')
        KUBECONFIG = credentials('kubeconfig-file')
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    def shortSha = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def timestamp = sh(returnStdout: true, script: 'date +%Y%m%d-%H%M%S').trim()
                    env.IMAGE_TAG = "${shortSha}-${timestamp}"
                }
                
                sh """
                    docker login -u ${DOCKER_CREDENTIALS_USR} -p ${DOCKER_CREDENTIALS_PSW}
                    docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest
                """
            }
        }
        
        stage('Push') {
            steps {
                sh """
                    docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                    docker push ${DOCKER_IMAGE}:latest
                """
            }
        }
        
        stage('Deploy') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl cluster-info
                    kubectl set image deployment/langflow-api-prod \
                        langflow-api-prod-image=${DOCKER_IMAGE}:${IMAGE_TAG} \
                        -n ${NAMESPACE}
                    kubectl rollout status deployment/langflow-api-prod -n ${NAMESPACE} --timeout=5m
                """
            }
        }
        
        stage('Verify') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}
                    kubectl get pods -n ${NAMESPACE} -l app=langflow-api-prod
                    
                    POD=\$(kubectl get pod -n ${NAMESPACE} -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')
                    kubectl exec -n ${NAMESPACE} \$POD -- curl -f http://localhost:7860/health
                """
            }
        }
    }
    
    post {
        failure {
            sh """
                export KUBECONFIG=${KUBECONFIG}
                echo "Deployment failed, rolling back..."
                kubectl rollout undo deployment/langflow-api-prod -n ${NAMESPACE}
            """
        }
        always {
            sh 'docker logout'
        }
    }
}
```

## 🔧 Manual Deployment Script

For manual deployments or testing, create `manual-deploy.sh`:

```bash
#!/bin/bash

set -e

# Configuration
DOCKER_IMAGE="cera123/langflow"
NAMESPACE="prod"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting deployment...${NC}"

# Get current deployment info
CURRENT_IMAGE=$(kubectl get deployment langflow-api-prod -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
echo -e "${YELLOW}Current image: $CURRENT_IMAGE${NC}"

# Generate new tag
SHORT_SHA=$(git rev-parse --short HEAD)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
NEW_TAG="${SHORT_SHA}-${TIMESTAMP}"
NEW_IMAGE="${DOCKER_IMAGE}:${NEW_TAG}"

echo -e "${YELLOW}New image: $NEW_IMAGE${NC}"

# Build
echo -e "${GREEN}Building Docker image...${NC}"
docker build -t $NEW_IMAGE .
docker tag $NEW_IMAGE ${DOCKER_IMAGE}:latest

# Push
echo -e "${GREEN}Pushing to registry...${NC}"
docker push $NEW_IMAGE
docker push ${DOCKER_IMAGE}:latest

# Deploy
echo -e "${GREEN}Updating Kubernetes deployment...${NC}"
kubectl set image deployment/langflow-api-prod \
    langflow-api-prod-image=$NEW_IMAGE \
    -n $NAMESPACE

# Wait for rollout
echo -e "${GREEN}Waiting for rollout to complete...${NC}"
if kubectl rollout status deployment/langflow-api-prod -n $NAMESPACE --timeout=5m; then
    echo -e "${GREEN}Deployment successful!${NC}"
    kubectl get pods -n $NAMESPACE -l app=langflow-api-prod
    
    # Health check
    sleep 10
    POD=$(kubectl get pod -n $NAMESPACE -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')
    if kubectl exec -n $NAMESPACE $POD -- curl -f http://localhost:7860/health; then
        echo -e "${GREEN}Health check passed!${NC}"
    else
        echo -e "${RED}Health check failed!${NC}"
        exit 1
    fi
else
    echo -e "${RED}Deployment failed!${NC}"
    echo -e "${YELLOW}Rolling back...${NC}"
    kubectl rollout undo deployment/langflow-api-prod -n $NAMESPACE
    exit 1
fi
```

## 🔍 Best Practices

### 1. Image Tagging Strategy

```bash
# Good: Use git SHA + timestamp
IMAGE_TAG="${GIT_SHA}-$(date +%Y%m%d-%H%M%S)"

# Bad: Only use 'latest'
IMAGE_TAG="latest"
```

### 2. Health Checks

Always verify health after deployment:

```bash
# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=langflow-api-prod -n prod --timeout=300s

# Check health endpoint
POD=$(kubectl get pod -n prod -l app=langflow-api-prod -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n prod $POD -- curl -f http://localhost:7860/health
```

### 3. Rollback Strategy

```bash
# Always have a rollback plan
if ! kubectl rollout status deployment/langflow-api-prod -n prod --timeout=5m; then
    echo "Deployment failed, rolling back..."
    kubectl rollout undo deployment/langflow-api-prod -n prod
    exit 1
fi
```

### 4. Notifications

Add notifications to your pipeline:

```bash
# Slack notification
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"Langflow deployment to production completed successfully\"}" \
    $SLACK_WEBHOOK_URL

# Email notification
echo "Deployment completed" | mail -s "Langflow Production Deployment" admin@example.com
```

## 🎯 Deployment Checklist

Before each deployment:

- [ ] Tests passed in CI
- [ ] Docker image built successfully
- [ ] Image pushed to registry
- [ ] Staging environment tested
- [ ] Database migrations (if any)
- [ ] ConfigMaps/Secrets updated (if needed)
- [ ] Resource limits appropriate
- [ ] Monitoring/alerts configured
- [ ] Rollback plan ready
- [ ] Team notified

## 📊 Monitoring Deployment

```bash
# Watch deployment progress
kubectl get pods -n prod -l app=langflow-api-prod -w

# Check deployment history
kubectl rollout history deployment/langflow-api-prod -n prod

# Check events
kubectl get events -n prod --sort-by='.lastTimestamp' | grep langflow

# Monitor resource usage
kubectl top pod -l app=langflow-api-prod -n prod
```

## 🚨 Troubleshooting CI/CD

### Image Pull Errors

```bash
# Verify image exists
docker pull cera123/langflow:your-tag

# Check imagePullSecrets if using private registry
kubectl create secret docker-registry regcred \
    --docker-server=docker.io \
    --docker-username=your-username \
    --docker-password=your-password \
    -n prod
```

### Timeout Issues

```bash
# Increase timeout in deployment
kubectl patch deployment langflow-api-prod -n prod \
    -p '{"spec":{"progressDeadlineSeconds":600}}'
```

### Permission Issues

```bash
# Check service account permissions
kubectl auth can-i update deployment -n prod --as=system:serviceaccount:prod:default
```

## 🔗 Integration with Other Tools

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: langflow
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/langflow-k8s
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Helm Chart (Advanced)

Consider creating a Helm chart for more flexible deployments:

```bash
helm create langflow-chart
# Then package your manifests into the chart
```

## 📚 Additional Resources

- [Kubernetes CI/CD Best Practices](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)

