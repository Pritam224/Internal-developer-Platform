# Internal Developer Platform (IDP)

## Overview

A Kubernetes-based Internal Developer Platform that provides self-service infrastructure and deployment capabilities for developers through a GitOps-driven workflow.

The platform combines **Backstage** (developer portal), **Crossplane** (infrastructure provisioning), **ArgoCD** (GitOps delivery), and **Kyverno** (policy enforcement) to eliminate operational bottlenecks while maintaining governance, security, and consistency.

Built on Azure (AKS), following cloud-native and platform engineering principles.

---

## Problem Statement

In many organizations, developers depend on DevOps/infrastructure teams for routine tasks:

- Creating Kubernetes namespaces
- Configuring RBAC permissions
- Provisioning databases and storage
- Setting up ingress and DNS
- Managing secrets
- Creating CI/CD pipelines
- Deploying applications

This creates operational delays, inconsistent configurations, security risks, duplicated effort, and slower developer onboarding.

This platform solves these problems through **self-service with guardrails** — developers get what they need instantly, while platform engineers maintain control.

---

## Architecture

### High-Level Flow

```
Developer
   ↓
Backstage (IDP Portal — templates, catalog, docs)
   ↓
Git Repository (single source of truth)
   ↓
ArgoCD (GitOps — syncs desired state to cluster)
   ├── Crossplane (provisions Azure resources — Postgres, KV, Storage)
   ├── Helm Releases (application deployments)
   ├── Namespace + RBAC + Quotas (K8s manifests)
   └── Kyverno (policy enforcement — guardrails)

Base Infrastructure (bootstrapped with Terraform):
   AKS, VNet, ACR, Key Vault, DNS Zone
```

### Self-Service Workflow

```
1. Developer fills a Backstage template ("New microservice environment")
2. Backstage scaffolds a PR to the GitOps repo:
   - Namespace YAML
   - RBAC RoleBindings
   - Resource Quotas
   - Network Policies
   - Crossplane Claim (database, storage)
   - Helm values for the app
3. PR reviewed → merged
4. ArgoCD detects change → syncs to cluster
5. Crossplane provisions Azure resources (Postgres, Storage, etc.)
6. Kubernetes creates namespace, RBAC, quotas
7. App deployed via Helm through ArgoCD
8. Kyverno enforces policies (no privileged containers, required labels, resource limits)
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        DEVELOPER                                 │
│                           ↓                                      │
│                    ┌──────────────┐                              │
│                    │  Backstage   │  (Portal + Templates)        │
│                    │  IDP Portal  │                              │
│                    └──────┬───────┘                              │
│                           ↓                                      │
│                    ┌──────────────┐                              │
│                    │  Git Repo    │  (GitOps Source of Truth)     │
│                    │  (GitHub)    │                              │
│                    └──────┬───────┘                              │
│                           ↓                                      │
│              ┌────────────────────────┐                          │
│              │       ArgoCD           │  (GitOps Controller)     │
│              └───┬────┬────┬────┬────┘                          │
│                  │    │    │    │                                │
│          ┌───────┘    │    │    └────────┐                       │
│          ↓            ↓    ↓            ↓                       │
│   ┌───────────┐ ┌─────────┐ ┌────────┐ ┌─────────┐            │
│   │Crossplane │ │  Helm   │ │  K8s   │ │ Kyverno │            │
│   │(Azure     │ │Releases │ │RBAC +  │ │(Policy  │            │
│   │Resources) │ │(Apps)   │ │Quotas  │ │Engine)  │            │
│   └─────┬─────┘ └────┬────┘ └────────┘ └─────────┘            │
│         ↓             ↓                                         │
│   ┌───────────┐ ┌──────────┐                                   │
│   │ Azure     │ │  AKS     │                                   │
│   │ Postgres  │ │  Pods    │                                   │
│   │ Storage   │ │  Services│                                   │
│   │ Key Vault │ │  Ingress │                                   │
│   └───────────┘ └──────────┘                                   │
│                                                                  │
│   ┌──────────────────────────────────────────────┐              │
│   │           Observability Layer                 │              │
│   │  Prometheus  │  Grafana  │  Loki  │  Alerts  │              │
│   └──────────────────────────────────────────────┘              │
│                                                                  │
│   ┌──────────────────────────────────────────────┐              │
│   │        Base Infrastructure (Terraform)        │              │
│   │  AKS  │  VNet  │  ACR  │  Key Vault  │  DNS  │              │
│   └──────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Component | Technology | Why |
|---|---|---|
| **Developer Portal** | Backstage | CNCF standard IDP, templates, software catalog, TechDocs |
| **Container Orchestration** | AKS (Azure Kubernetes Service) | Managed K8s, Azure-native integrations |
| **Base Infrastructure IaC** | Terraform | Bootstrap AKS, VNet, ACR, DNS — one-time setup |
| **Self-Service Infra** | Crossplane | K8s-native, GitOps-compatible, drift-correcting, declarative |
| **CI (Build + Test)** | GitHub Actions | Build images, run tests, push to ACR |
| **CD / GitOps** | ArgoCD | Declarative, drift detection, auto-sync, rollback |
| **Packaging** | Helm | Reusable app deployment charts |
| **Policy Engine** | Kyverno | K8s-native, simpler than OPA, validate/mutate/generate |
| **Secrets Management** | Azure Key Vault + CSI Driver | Secrets mounted as tmpfs, auto-rotated, no K8s secrets |
| **Observability** | Prometheus + Grafana + Loki | Metrics, dashboards, log aggregation |
| **Authentication** | Entra ID (Azure AD) | SSO, RBAC integration, workload identity |
| **Database** | PostgreSQL Flexible Server | Managed, VNet-integrated, HA, provisioned via Crossplane |
| **Container Registry** | Azure Container Registry (ACR) | Private, AKS-integrated, geo-replication capable |

---

## Core Features

### 1. Namespace Self-Service

Developers request namespaces through Backstage templates.

The platform automatically:

- Creates the namespace
- Applies resource quotas (CPU/memory limits per namespace)
- Configures RBAC (developer, admin, read-only roles)
- Applies labels and annotations (team, cost-center, environment)
- Configures network policies (namespace isolation by default)
- Registers the namespace in Backstage's software catalog

### 2. RBAC Automation

Role-based access tied to Entra ID groups:

| Role | Access |
|---|---|
| `namespace-admin` | Full access within the namespace |
| `namespace-developer` | Deploy, view logs, exec into pods |
| `namespace-viewer` | Read-only (dashboards, logs) |

RBAC manifests are generated by Backstage templates and synced by ArgoCD — no manual `kubectl` role management.

### 3. Infrastructure Provisioning (Crossplane)

Developers request cloud resources through Backstage → Crossplane provisions them.

**Supported resources (Crossplane Compositions):**

| Resource | Azure Service | What's Abstracted |
|---|---|---|
| Database | PostgreSQL Flexible Server | Server + DB + firewall rules + KV secret |
| Storage | Storage Account + Container | Account + container + RBAC + PE |
| Cache | Azure Cache for Redis | Instance + firewall + connection string |
| DNS Record | Azure DNS | A/CNAME record in the app's zone |

**Example Crossplane Claim** (what a dev submits):

```yaml
apiVersion: platform.idp.dev/v1alpha1
kind: Database
metadata:
  name: orders-db
  namespace: orders-team
spec:
  engine: postgresql
  version: "16"
  size: small          # small = Burstable B2s, medium = GP D4ds_v5
  environment: dev
  backup: enabled
```

**The Composition handles** (what the platform team defined):

- PostgreSQL Flexible Server creation
- VNet integration (delegated subnet)
- Admin password generation → stored in Key Vault
- Connection string → K8s secret via CSI driver
- Diagnostic settings → Log Analytics
- Monitoring alerts

### 4. Application Deployment

Applications deploy through a GitOps workflow:

```
Developer pushes code
   ↓
GitHub Actions: lint → test → build image → push to ACR → update Helm values in GitOps repo
   ↓
ArgoCD detects change in GitOps repo
   ↓
ArgoCD syncs: Helm release deployed to AKS
   ↓
App running with correct config, secrets from KV, ingress configured
```

**Reusable Helm chart** supports:

- Environment-specific values (dev/staging/prod)
- Configurable replicas, resources, HPA
- Ingress with TLS (cert-manager)
- Readiness/liveness probes
- Service account with workload identity annotations
- Prometheus scrape annotations

### 5. CI/CD Pipeline Generation

Backstage templates generate a complete project scaffold:

```
new-microservice/
├── src/                          # App code (starter template)
├── Dockerfile                    # Multi-stage build
├── .github/
│   └── workflows/
│       └── ci.yaml               # GitHub Actions: lint, test, build, push
├── helm/
│   └── values-dev.yaml           # Helm values per env
├── gitops/
│   ├── namespace.yaml            # Namespace + quotas + RBAC
│   ├── crossplane-db.yaml        # Database claim
│   ├── argocd-app.yaml           # ArgoCD Application manifest
│   └── kyverno-exceptions.yaml   # Policy exceptions if needed
└── README.md
```

Developer gets a working repo with CI pipeline, GitOps manifests, and infrastructure claims — ready to `git push` and have everything provisioned.

### 6. GitOps with ArgoCD

ArgoCD manages all cluster state:

- **App of Apps pattern:** One root ArgoCD Application manages all team applications
- **Auto-sync:** Changes merged to `main` → auto-deployed
- **Drift detection:** If someone `kubectl edit`s a resource, ArgoCD reverts it
- **Rollback:** One-click rollback to any previous Git commit
- **Health checks:** ArgoCD shows real-time health of every resource
- **Notifications:** Slack/Teams alerts on sync failures

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: orders-service
  namespace: argocd
spec:
  project: orders-team
  source:
    repoURL: https://github.com/org/gitops-repo
    targetRevision: main
    path: teams/orders/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: orders-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 7. Policy Enforcement (Kyverno)

Guardrails that enforce standards without blocking developers:

| Policy | Type | What it does |
|---|---|---|
| `require-labels` | Validate | All pods must have `team`, `app`, `env` labels |
| `disallow-privileged` | Validate | Block privileged containers |
| `require-resource-limits` | Validate | All containers must have CPU/memory limits |
| `require-probes` | Validate | Deployments must have readiness/liveness probes |
| `mutate-pull-policy` | Mutate | Force `imagePullPolicy: Always` for `latest` tags |
| `generate-network-policy` | Generate | Auto-create default-deny NetworkPolicy per namespace |
| `restrict-registries` | Validate | Only allow images from our ACR |

**Example Kyverno policy:**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-labels
      match:
        any:
          - resources:
              kinds: ["Deployment", "StatefulSet"]
      validate:
        message: "Labels 'team', 'app', and 'env' are required."
        pattern:
          metadata:
            labels:
              team: "?*"
              app: "?*"
              env: "?*"
```

### 8. Secrets Management

Zero secrets in Git, zero secrets in K8s etcd:

```
Azure Key Vault (source of truth)
   ↓
CSI Secret Store Driver (mounts as tmpfs in pods)
   ↓
Pod reads /mnt/secrets/db-password (in-memory, never on disk)
```

- Crossplane writes provisioned credentials to Key Vault automatically
- Workload identity — pods authenticate to KV without any stored secrets
- Auto-rotation every 10 seconds if KV value changes
- Audit trail on every secret access via KV diagnostic logs

### 9. Observability

| Layer | Tool | What |
|---|---|---|
| Metrics | Prometheus + Grafana | Node/pod metrics, custom app metrics, dashboards |
| Logs | Loki + Promtail | Centralized log aggregation, queryable |
| Alerts | AlertManager | Slack/PagerDuty notifications |
| Traces | (Future) Jaeger/Tempo | Distributed tracing |
| Cost | Label-based attribution | Per-team cost breakdown via labels |

**Pre-built Grafana dashboards:**

- Platform overview (namespaces, pods, resource usage)
- Per-team resource consumption (FinOps)
- ArgoCD sync status
- Crossplane resource health
- Kyverno policy violations

---

## Security

| Concern | Implementation |
|---|---|
| Authentication | Entra ID SSO (Backstage, ArgoCD, Grafana) |
| Authorization | K8s RBAC via Entra ID groups, namespace-scoped |
| Network | Network policies (default-deny per namespace), private AKS |
| Secrets | Key Vault + CSI driver, workload identity (no stored creds) |
| Images | ACR-only policy (Kyverno), image scanning (Defender) |
| GitOps | All changes via PR → review → merge → ArgoCD (no direct kubectl) |
| Policies | Kyverno enforces labels, limits, probes, registries |
| Audit | AKS audit logs, KV access logs, ArgoCD activity, Git history |

---

## Repository Structure

```
idp-platform/
├── README.md
│
├── terraform/                        # Base infrastructure (one-time bootstrap)
│   ├── modules/
│   │   ├── aks/                      # AKS cluster + node pools
│   │   ├── network/                  # VNet, subnets, NSGs, peering
│   │   ├── acr/                      # Container registry
│   │   ├── keyvault/                 # Key Vault + RBAC
│   │   └── dns/                      # Azure DNS zone
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   └── backend.tf
│
├── crossplane/                       # Crossplane setup + compositions
│   ├── provider-azure.yaml           # Azure provider config
│   ├── compositions/
│   │   ├── database/                 # PostgreSQL composition + XRD
│   │   ├── storage/                  # Storage account composition
│   │   ├── cache/                    # Redis composition
│   │   └── dns-record/              # DNS record composition
│   └── claims/                       # Example claims (for docs)
│
├── argocd/                           # ArgoCD setup
│   ├── install/                      # ArgoCD Helm values
│   ├── projects/                     # ArgoCD Projects (per team)
│   ├── apps/                         # App-of-apps root
│   └── notifications/                # Slack/Teams notification config
│
├── kyverno/                          # Policy engine
│   ├── install/                      # Kyverno Helm values
│   └── policies/
│       ├── require-labels.yaml
│       ├── disallow-privileged.yaml
│       ├── require-resource-limits.yaml
│       ├── require-probes.yaml
│       ├── restrict-registries.yaml
│       └── generate-network-policy.yaml
│
├── backstage/                        # Developer portal
│   ├── app-config.yaml              # Backstage config
│   ├── catalog/                      # Software catalog entities
│   └── templates/
│       ├── new-namespace/            # Namespace provisioning template
│       ├── new-microservice/         # Full microservice scaffold
│       ├── new-database/             # Database provisioning template
│       └── new-storage/              # Storage provisioning template
│
├── helm-charts/                      # Reusable Helm charts
│   └── microservice/                 # Generic microservice chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── hpa.yaml
│           ├── ingress.yaml
│           ├── serviceaccount.yaml
│           └── secret-provider.yaml  # KV CSI SecretProviderClass
│
├── observability/                    # Monitoring stack
│   ├── prometheus/                   # kube-prometheus-stack values
│   ├── grafana/
│   │   └── dashboards/              # Pre-built JSON dashboards
│   ├── loki/                         # Loki + Promtail values
│   └── alertmanager/                 # Alert rules + routes
│
├── gitops/                           # Team GitOps manifests (ArgoCD syncs this)
│   └── teams/
│       └── example-team/
│           ├── dev/
│           │   ├── namespace.yaml
│           │   ├── rbac.yaml
│           │   ├── quotas.yaml
│           │   ├── network-policy.yaml
│           │   ├── crossplane-db.yaml
│           │   └── app-release.yaml
│           └── prod/
│
├── docs/                             # Documentation
│   ├── getting-started.md
│   ├── architecture.md
│   ├── onboarding-a-team.md
│   ├── backstage-templates.md
│   ├── crossplane-compositions.md
│   └── troubleshooting.md
│
└── scripts/                          # Utility scripts
    ├── bootstrap.sh                  # Initial cluster setup
    ├── install-crossplane.sh
    ├── install-argocd.sh
    └── install-kyverno.sh
```

---

## Implementation Phases

### Phase 1 — Foundation (Week 1-2)

**Goal:** Base infrastructure + GitOps pipeline running

- [ ] Terraform: AKS cluster + VNet + ACR + Key Vault + DNS
- [ ] ArgoCD: Install on AKS, configure GitHub repo as source
- [ ] App-of-apps pattern: Root ArgoCD Application
- [ ] GitHub Actions: CI pipeline (build → push to ACR)
- [ ] Helm chart: Generic microservice chart (deploy, svc, hpa, ingress)
- [ ] Deploy a sample app end-to-end via GitOps

**Milestone:** Push code → GitHub Actions builds → ArgoCD deploys → app running on AKS

### Phase 2 — Self-Service Infra (Week 3-4)

**Goal:** Developers can provision cloud resources via Git

- [ ] Crossplane: Install, configure Azure provider
- [ ] Composition: PostgreSQL (server + DB + KV secret + monitoring)
- [ ] Composition: Storage Account (account + container + RBAC)
- [ ] Composition: DNS Record
- [ ] Namespace automation: YAML templates for namespace + RBAC + quotas + network policy
- [ ] Key Vault CSI: SecretProviderClass for pod secret mounting
- [ ] Workload Identity: Federated credentials for pod-to-Azure auth

**Milestone:** Create a Crossplane Database claim → Postgres provisioned → connection string in KV → app reads it via CSI

### Phase 3 — Policy & Security (Week 5)

**Goal:** Guardrails enforced automatically

- [ ] Kyverno: Install on AKS
- [ ] Policies: require-labels, disallow-privileged, require-limits, require-probes, restrict-registries
- [ ] Generate policy: Auto-create default-deny NetworkPolicy per namespace
- [ ] Mutate policy: Force imagePullPolicy for latest tags
- [ ] Policy reporting: Kyverno policy reports dashboard in Grafana
- [ ] RBAC: Entra ID group → K8s ClusterRole/RoleBinding mapping

**Milestone:** Deploy a pod without labels → blocked by Kyverno. Deploy with labels → allowed.

### Phase 4 — Developer Portal (Week 6-7)

**Goal:** Backstage as the self-service frontend

- [ ] Backstage: Install and configure (Entra ID SSO)
- [ ] Software Catalog: Register existing services
- [ ] Template: "New Namespace" → generates namespace + RBAC + quotas PR
- [ ] Template: "New Microservice" → scaffolds repo + CI + Helm + GitOps manifests
- [ ] Template: "New Database" → generates Crossplane claim PR
- [ ] TechDocs: Platform documentation inside Backstage
- [ ] ArgoCD plugin: Show deployment status in Backstage

**Milestone:** Developer fills template in Backstage → PR created → merged → ArgoCD deploys → resource visible in Backstage catalog

### Phase 5 — Observability & FinOps (Week 8)

**Goal:** Full visibility into platform health and cost

- [ ] kube-prometheus-stack: Install (Prometheus + Grafana + AlertManager)
- [ ] Loki + Promtail: Centralized logging
- [ ] Dashboards: Platform overview, per-team resource usage, ArgoCD sync, Crossplane health
- [ ] Alerts: Node NotReady, CrashLoopBackOff, sync failures, policy violations
- [ ] Cost attribution: Label-based resource cost breakdown per team
- [ ] Grafana SSO: Entra ID integration

**Milestone:** Full dashboard showing all teams, resource usage, costs, policy violations, deployment status

---

## Future Enhancements

- [ ] **Multi-cluster:** ArgoCD managing dev + staging + prod clusters
- [ ] **Preview environments:** PR creates ephemeral namespace, destroyed on merge
- [ ] **AI-assisted troubleshooting:** LLM-powered incident analysis from logs/metrics
- [ ] **Cost budgets:** Per-team cost limits enforced via Crossplane + Kyverno
- [ ] **Service mesh:** Istio/Linkerd for mTLS between services
- [ ] **Automated certificate management:** cert-manager + Let's Encrypt
- [ ] **Chaos engineering:** Chaos Mesh for resilience testing
- [ ] **Multi-cloud Crossplane:** Extend compositions to AWS/GCP

---

## How to Run

### Prerequisites

- Azure subscription
- `az` CLI authenticated
- `terraform` >= 1.5
- `kubectl`
- `helm`
- GitHub account + personal access token

### Bootstrap

```bash
# 1. Provision base infrastructure
cd terraform/environments/dev
terraform init && terraform apply

# 2. Get AKS credentials
az aks get-credentials -g rg-idp-dev -n aks-idp-dev

# 3. Install platform components
./scripts/install-argocd.sh
./scripts/install-crossplane.sh
./scripts/install-kyverno.sh

# 4. ArgoCD syncs everything else from Git
kubectl apply -f argocd/apps/root-app.yaml
```

### Verify

```bash
# Check ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
# → https://localhost:8080

# Check Crossplane
kubectl get providers
kubectl get compositions

# Check Kyverno
kubectl get clusterpolicies

# Check a Crossplane claim
kubectl get databases -A
```

---

## Project Vision

This platform demonstrates the shift from **"DevOps as a service desk"** to **"DevOps as a product team"** — building the platform that empowers developers to self-serve while maintaining governance, security, and cost control.

Built with the tools that define Platform Engineering in 2026: **Backstage, Crossplane, ArgoCD, Kyverno**.

---

## References

- [Backstage.io](https://backstage.io/)
- [Crossplane Docs](https://docs.crossplane.io/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Kyverno Docs](https://kyverno.io/docs/)
- [Azure AKS Docs](https://learn.microsoft.com/en-us/azure/aks/)
- [Platform Engineering Maturity Model](https://tag-app-delivery.cncf.io/whitepapers/platform-eng-maturity-model/)
