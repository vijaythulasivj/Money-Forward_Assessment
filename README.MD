# MLOps Platform Engineering - Generic Helm Deployment Platform

## 1. Overview

This project implements a reusable and environment-agnostic Helm deployment platform for ML APIs running on Kubernetes.

The primary objective is to eliminate duplicated Kubernetes manifests and manual deployment activities across Dev, Staging, and Production environments.

The solution provides:

- One generic Helm chart
- Minimal environment-specific values files
- Local Minikube deployment
- ML API accessible from the local PC
- Helm unit tests
- GitHub Actions CI/CD
- Helm chart packaging
- Private OCI repository publishing design
- Terraform-based Infrastructure as Code example
- Horizontal Pod Autoscaling
- Kubernetes Secret integration
- Versioning and security considerations

The key design principle is:

> **Build the deployment logic once and configure it per environment through values.**

This allows Machine Learning Engineers to deploy different ML APIs using the same standardized deployment framework.

---

## 2. Problem & Solution

### Problem

Managing Kubernetes deployments separately for Dev, Staging, and Production can result in duplicated manifests and environment-specific configuration.

For example:

<div align="center">

<pre>
Dev Kubernetes Manifests
Staging Kubernetes Manifests
Production Kubernetes Manifests
</pre>

</div>

This can lead to:

- Duplicate configuration
- Configuration drift
- Manual deployment processes
- Higher maintenance effort
- Environment-specific inconsistencies
- Slower deployment cycles

### Solution

The proposed solution uses a single generic Helm chart with environment-specific values.

<div align="center">

<pre>
                 Generic Helm Chart
                        |
          +-------------+-------------+
          |             |             |
          v             v             v
     values-dev    values-staging  values-prod
          |             |             |
          v             v             v
         Dev         Staging       Production
</pre>

</div>

The Kubernetes deployment logic remains unchanged while environment-specific properties such as replicas, resources, service type, image configuration, and autoscaling are controlled through values files.

This provides a reusable platform that can be consumed by multiple ML engineering teams.

---

## 3. Architecture

### Overall Architecture

<div align="center">

<pre>
                         GitHub Repository
                                |
                                v
                       GitHub Actions CI/CD
                                |
                 +--------------+--------------+
                 |                             |
                 v                             v
             Helm Lint                    Helm Unit Tests
                 |                             |
                 +--------------+--------------+
                                |
                                v
                         Helm Template
                                |
                                v
                          Helm Package
                                |
                                v
                         Helm Chart (.tgz)
                                |
                                v
                    Private OCI Repository
                       (production design)
                                |
                                v
                           Kubernetes
                                |
              +-----------------+-----------------+
              |                 |                 |
             Dev             Staging           Production
              |                 |                 |
       values-dev.yaml   values-staging.yaml  values-prod.yaml
</pre>

</div>

### Local Deployment Architecture

<div align="center">

<pre>
Docker Image
     |
     v
  Minikube
     |
     v
 Generic Helm Chart
     |
     v
 values-dev.yaml
     |
     v
 Kubernetes Deployment
     |
     v
 Kubernetes Service
     |
     v
 Local PC
     |
     +---- GET /
     |
     +---- GET /health
     |
     +---- GET /predict
</pre>

</div>

The sample API is implemented using FastAPI and is intentionally simple because the primary focus of this assignment is the MLOps deployment platform rather than the ML model itself.

---

## 4. Repository Structure

```text
Money-Forward_Assessment/
│
├── .github/
│   └── workflows/
│       └── helm-ci-cd.yml
│
├── app/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
│
├── helm/
│   └── ml-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       │
│       ├── templates/
│       │   ├── _helpers.tpl
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── hpa.yaml
│       │   └── serviceaccount.yaml
│       │
│       └── tests/
│           ├── deployment_test.yaml
│           ├── service_test.yaml
│           └── hpa_test.yaml
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── .gitignore
└── README.MD
```

### Directory Responsibilities

| Directory/File | Purpose |
|---|---|
| `app/` | Sample FastAPI ML API |
| `helm/ml-api/` | Generic Helm chart |
| `helm/ml-api/templates/` | Reusable Kubernetes templates |
| `helm/ml-api/tests/` | Helm unit tests |
| `values-dev.yaml` | Development configuration |
| `values-staging.yaml` | Staging configuration |
| `values-prod.yaml` | Production configuration |
| `.github/workflows/` | CI/CD automation |
| `terraform/` | Infrastructure as Code example |
| `README.MD` | Project documentation |

---

## 5. Generic Helm Chart Design

The Helm chart is designed around separation of deployment logic and environment configuration.

### Reusable Templates

The chart contains reusable Kubernetes templates for:

- Deployment
- Service
- HorizontalPodAutoscaler
- ServiceAccount
- Common labels and naming
- Optional Secret integration

The templates do not contain environment-specific values.

### Environment Values

Environment-specific configuration is provided through:

```text
values-dev.yaml
values-staging.yaml
values-prod.yaml
```

For example:

```yaml
replicaCount: 2

resources:
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 4
```

The same deployment template can therefore be reused across all environments.

### Benefits

- No duplicated Kubernetes manifests
- Reduced configuration drift
- Easier maintenance
- Standardized deployment process
- Easier onboarding for ML Engineers
- Environment-specific configuration remains explicit

---

## 6. Dev / Staging / Production Configuration

The same Helm chart is used for all environments.

Only the values change.

### Development

File:

```text
helm/ml-api/values-dev.yaml
```

Configuration:

```text
Replicas:             1
Service:              NodePort
Autoscaling:          Disabled
Resource allocation:  Lower
```

NodePort is used because it makes the application easily accessible from a local Minikube environment.

Example:

```yaml
replicaCount: 1

service:
  type: NodePort

autoscaling:
  enabled: false
```

### Staging

File:

```text
helm/ml-api/values-staging.yaml
```

Configuration:

```text
Replicas:             2
Service:              ClusterIP
Autoscaling:          Enabled
Minimum replicas:     2
Maximum replicas:     4
```

Example:

```yaml
replicaCount: 2

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 4
  targetCPUUtilizationPercentage: 70
```

### Production

File:

```text
helm/ml-api/values-prod.yaml
```

Configuration:

```text
Replicas:             3
Service:              ClusterIP
Autoscaling:          Enabled
Minimum replicas:     3
Maximum replicas:     10
```

Example:

```yaml
replicaCount: 3

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 60
```

The MLE therefore only needs to select the appropriate values file rather than modify Kubernetes templates.

---

## 7. Local Minikube Deployment

The Helm chart has been deployed and tested on a local Minikube Kubernetes cluster.

### Start Minikube

```bash
minikube start
```

Verify:

```bash
minikube status
```

Expected:

```text
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Build the Sample API Image

```bash
docker build -t ml-api:1.0.0 ./app
```

### Load the Image into Minikube

```bash
minikube image load ml-api:1.0.0
```

### Deploy Using Helm

```bash
helm upgrade --install ml-api ./helm/ml-api \
  -f ./helm/ml-api/values-dev.yaml
```

Verify the deployment:

```bash
kubectl get pods
```

Verify the service:

```bash
kubectl get svc
```

The development environment uses a NodePort service.

### Access the API

Get the local service URL:

```bash
minikube service ml-api-ml-api --url
```

Example:

```text
http://127.0.0.1:61318
```

### Test Root Endpoint

```bash
curl http://127.0.0.1:61318
```

Expected:

```json
{
  "message": "Hello from MLOps ML API",
  "version": "1.0.0"
}
```

### Test Health Endpoint

```bash
curl http://127.0.0.1:61318/health
```

Expected:

```json
{
  "status": "healthy"
}
```

### Test Prediction Endpoint

```bash
curl http://127.0.0.1:61318/predict
```

Expected:

```json
{
  "prediction": "sample-prediction",
  "model_version": "1.0.0"
}
```

This demonstrates that the Helm-deployed ML API is callable directly from the local PC.

---

## 8. Helm Test Cases

The Helm chart contains unit tests for the major deployment components.

Test suites:

```text
helm/ml-api/tests/
├── deployment_test.yaml
├── service_test.yaml
└── hpa_test.yaml
```

### Deployment Tests

The deployment tests validate:

- Deployment resource creation
- Container image
- Container port
- Readiness probe
- Liveness probe
- Replica count

### Service Tests

The service tests validate:

- Service creation
- Service port
- Target port
- NodePort configuration

### HPA Tests

The HPA tests validate:

- HPA disabled behavior
- HPA creation when enabled
- Minimum replicas
- Maximum replicas

### Test Result

The complete test suite currently contains:

```text
Test Suites: 3 passed
Tests:       14 passed
Failures:    0
```

The tests are also executed automatically as part of GitHub Actions CI.

---

## 9. CI/CD Pipeline

GitHub Actions is used for Helm chart CI/CD.

### Pipeline Flow

<div align="center">

<pre>
Git Push / Pull Request
          |
          v
    Checkout Repository
          |
          v
       Setup Helm
          |
          v
       Helm Lint
          |
          v
  Template Dev Environment
          |
          v
 Template Staging Environment
          |
          v
 Template Production Environment
          |
          v
     Helm Unit Tests
          |
          v
      Helm Package
          |
          v
    Upload Artifact
</pre>

</div>

Workflow file:

```text
.github/workflows/helm-ci-cd.yml
```

### Helm Validation

The pipeline runs:

```bash
helm lint ./helm/ml-api
```

The chart is also rendered against all three environments:

```bash
helm template ml-api ./helm/ml-api \
  -f ./helm/ml-api/values-dev.yaml
```

```bash
helm template ml-api ./helm/ml-api \
  -f ./helm/ml-api/values-staging.yaml
```

```bash
helm template ml-api ./helm/ml-api \
  -f ./helm/ml-api/values-prod.yaml
```

### Unit Testing

Helm unit tests are executed during CI using the Helm unittest Docker image.

The pipeline validates all three test suites before packaging the chart.

### Helm Packaging

After successful validation:

```bash
helm package ./helm/ml-api --destination dist
```

This produces:

```text
dist/ml-api-0.1.0.tgz
```

The packaged chart is then uploaded as a GitHub Actions artifact.

### CI/CD Result

The current GitHub Actions pipeline successfully performs:

```text
Checkout
   ↓
Helm Setup
   ↓
Helm Lint
   ↓
Dev Template Validation
   ↓
Staging Template Validation
   ↓
Production Template Validation
   ↓
Helm Unit Tests
   ↓
Helm Package
   ↓
Artifact Upload
```

This ensures that only a validated and tested Helm package is produced by CI.

---

## 10. Private OCI Repository Publishing

Helm supports OCI-based chart repositories.

For a production cloud environment, the packaged Helm chart can be published to a private OCI-compatible registry.

Amazon ECR is one example of such a private registry.

### Production Publishing Flow

<div align="center">

<pre>
GitHub Actions
      |
      v
OIDC Authentication
      |
      v
Cloud IAM Role
      |
      v
Private OCI Registry
      |
      v
Helm Chart
</pre>

</div>

For example, with Amazon ECR:

```bash
aws ecr get-login-password --region <region> |
helm registry login \
  --username AWS \
  --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
```

The packaged chart can then be published using:

```bash
helm push \
  dist/ml-api-0.1.0.tgz \
  oci://<account-id>.dkr.ecr.<region>.amazonaws.com/ml-api-helm
```

### Cloud Account Limitation

This assessment environment does not provide an AWS/cloud account.

Therefore:

- The Helm chart is fully built, tested, packaged, and validated.
- The private cloud registry publishing flow is documented.
- No cloud resources or credentials are required for the local implementation.
- No AWS credentials are stored in the repository.
- The OCI publishing stage is a production design rather than an executed step.

In a production environment, GitHub Actions OIDC would be preferred over long-lived cloud access keys.

This provides short-lived credentials and avoids storing permanent cloud credentials in GitHub secrets.

---

## 11. Terraform / IaC

Terraform is included to demonstrate how the Helm deployment could be integrated into Infrastructure as Code.

Files:

```text
terraform/
├── main.tf
├── variables.tf
└── outputs.tf
```

The Terraform example demonstrates:

- Private ECR repository
- Helm provider
- Helm release
- Chart version
- Environment-specific values

Conceptually:

<div align="center">

<pre>
                Terraform
                    |
          +---------+---------+
          |                   |
          v                   v
    Private OCI Repo      Kubernetes
                              |
                              v
                        Helm Release
                              |
                              v
                       Generic ML API
</pre>

</div>

The Terraform configuration is intentionally illustrative.

The assignment states that the IaC implementation does not need to be executed because cloud infrastructure may incur costs.

Therefore, the Terraform configuration demonstrates the intended production implementation without requiring live cloud infrastructure.

---

## 12. Autoscaling & Secrets

### Autoscaling

The Helm chart supports Kubernetes Horizontal Pod Autoscaling using `autoscaling/v2`.

Example:

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 60
```

The same HPA template can therefore be reused across environments.

Current configuration:

```text
Dev          -> HPA disabled
Staging      -> 2 to 4 replicas
Production   -> 3 to 10 replicas
```

### Secrets

The chart supports consuming an existing Kubernetes Secret.

Example:

```yaml
secret:
  enabled: true
  existingSecret: ml-api-secret
```

The Deployment can consume it using:

```yaml
envFrom:
  - secretRef:
      name: ml-api-secret
```

Actual credentials should never be committed to Git.

For a production implementation, secrets could be managed using:

<div align="center">

<pre>
Cloud Secrets Manager
        |
        v
External Secrets Operator
        |
        v
Kubernetes Secret
        |
        v
ML API Pod
</pre>

</div>

This keeps sensitive values outside the Git repository.

---

## 13. Versioning & Security

### Versioning

Helm chart version and application version are maintained separately.

Example:

```yaml
version: 0.1.0
appVersion: "1.0.0"
```

### Chart Version

The Helm chart version represents changes to the deployment platform.

Example:

```text
0.1.0 -> Initial chart
0.2.0 -> New deployment functionality
1.0.0 -> Stable production chart
```

### Application Version

The application version represents the version of the ML API/application.

This allows the deployment platform and application to evolve independently.

### Recommended Production Versioning

<div align="center">

<pre>
Git Commit
    |
    v
CI Validation
    |
    v
Semantic Version
    |
    v
Helm Package
    |
    v
Immutable OCI Artifact
</pre>

</div>

### Security

The solution follows these security principles.

#### No Credentials in Git

Cloud credentials and application secrets should never be committed to the repository.

#### OIDC Authentication

GitHub Actions can use OIDC to obtain short-lived cloud credentials rather than storing long-lived access keys.

#### Kubernetes ServiceAccount

The application uses a dedicated ServiceAccount instead of relying on the default ServiceAccount.

#### Resource Limits

CPU and memory requests/limits are defined for predictable resource management.

#### Health Checks

Readiness and liveness probes allow Kubernetes to identify application health and manage unhealthy workloads.

#### Container Security

For a production implementation, the CI pipeline can additionally include:

- Container vulnerability scanning
- Dependency scanning
- SBOM generation
- Image signing
- Policy enforcement
- Kubernetes admission controls

---

## 14. Future / Outside-the-Box Improvements

The current implementation provides the required deployment foundation.

The following improvements could be added for a production-grade MLOps platform.

### GitOps

Argo CD or Flux could be used for declarative Kubernetes deployments.

<div align="center">

<pre>
GitHub
   |
   v
GitOps Repository
   |
   v
Argo CD / Flux
   |
   v
Kubernetes
</pre>

</div>

This provides improved auditability, drift detection, and rollback capabilities.

### Progressive Delivery

Production deployments could support:

- Canary releases
- Blue/Green deployments
- Automated rollback

This allows ML APIs to be gradually exposed to production traffic.

### ML-Specific Monitoring

Beyond infrastructure metrics, an MLOps platform should monitor:

- Prediction latency
- Prediction errors
- Request volume
- Model performance
- Data drift
- Model drift
- Feature distribution changes

### Observability

Prometheus and Grafana could be integrated for:

<div align="center">

<pre>
Metrics
   +
Dashboards
   +
Alerts
   +
Application Monitoring
</pre>

</div>

### Immutable Images

Instead of using mutable image tags such as:

```text
ml-api:latest
```

production deployments should use immutable identifiers such as:

```text
ml-api:<git-sha>
```

This makes deployments reproducible and improves rollback reliability.

### Additional CI Validation

The CI pipeline can be extended with:

- Helm schema validation
- Kubernetes manifest validation
- Container image scanning
- Dependency scanning
- Security policy checks
- Infrastructure security scanning

### Multi-Model Platform

The same platform could support multiple ML APIs without creating separate Kubernetes deployment templates.

For example:

<div align="center">

<pre>
Generic Helm Chart
       |
       +---- Recommendation API
       |
       +---- Fraud Detection API
       |
       +---- Classification API
       |
       +---- Forecasting API
</pre>

</div>

Each service would use the same deployment platform while supplying its own image and environment values.

---

## 15. Limitations & Conclusion

### Limitations

The following components are intentionally not executed against cloud infrastructure:

- Private cloud OCI registry
- Cloud IAM/OIDC integration
- Terraform apply

The reason is that the assessment environment does not provide a cloud account and the assignment explicitly states that the IaC implementation does not need to be executed.

The local Kubernetes implementation is fully demonstrated using Minikube.

### What Has Been Implemented

The current solution successfully demonstrates:

- Generic Helm chart
- Environment-specific values
- Dev/Staging/Production configuration
- Local Minikube deployment
- ML API accessible from the local PC
- Kubernetes Deployment
- Kubernetes Service
- Horizontal Pod Autoscaling configuration
- Kubernetes Secret integration
- Helm unit tests
- 3 test suites
- 14 passing tests
- Helm linting
- Helm template validation
- GitHub Actions CI/CD
- Helm chart packaging
- CI artifact generation
- Terraform IaC example

### Conclusion

This implementation addresses the core problem by replacing duplicated environment-specific Kubernetes manifests with a single reusable Helm chart.

The deployment model is:

<div align="center">

<pre>
One Generic Helm Chart
          +
Minimal Environment Values
          |
          v
Dev / Staging / Production
</pre>

</div>

The platform allows ML Engineers to focus on their ML APIs while the platform standardizes the Kubernetes deployment process.

The overall approach is:

<div align="center">

<pre>
Build Once
    |
    v
Configure Per Environment
    |
    v
Validate Automatically
    |
    v
Package
    |
    v
Publish to Private OCI Registry
    |
    v
Deploy Consistently
</pre>

</div>

> **Build the deployment logic once, configure it per environment, validate automatically, and deploy consistently.**
