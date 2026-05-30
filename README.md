# Internal Developer Platform (IDP)

## Overview

A Kubernetes-based Internal Developer Platform that provides self-service infrastructure and deployment capabilities for developers through a GitOps-driven workflow.

The platform combines **Backstage** (developer portal), **Crossplane** (infrastructure provisioning), **ArgoCD** (GitOps delivery), **Kyverno** (policy enforcement), and an **AI-powered debugging layer** (MCP + RAG) to eliminate operational bottlenecks while maintaining governance, security, and consistency.

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

AI Debugging Layer:
   MCP Server (live cluster tools — kubectl, ArgoCD, Prometheus)
   RAG Engine (indexed runbooks, docs, past incidents)
   AI CLI (Claude API — autonomous diagnosis)

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
│   │           AI Debugging Layer                  │              │
│   │  MCP Server │ RAG Engine │ Claude API │ CLI  │              │
│   └──────────────────────────────────────────────┘              │
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
| **AI Debugging** | MCP Server + Claude API | Live cluster tools exposed via Model Context Protocol |
| **Knowledge Retrieval** | RAG (ChromaDB + Embeddings) | Indexed runbooks and docs for context-aware diagnosis |

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

### 10. AI-Powered Debugging (MCP + RAG)

An AI-assisted debugging layer that autonomously diagnoses Kubernetes issues using live cluster data and indexed platform knowledge.

**Architecture:**

```
Developer: "my orders service is broken"
   ↓
AI Debug CLI (Claude API)
   ├── MCP Server → pulls live data (pod logs, events, metrics, ArgoCD status)
   └── RAG Engine → searches indexed runbooks, docs, past incidents
   ↓
AI Response: "OOMKilled — orders-service container exceeded 512Mi memory limit.
Prometheus shows memory climbing since last deploy. Runbook says: increase
limit to 1Gi or check for the known memory leak in v2.3. Here's the fix..."
```

**MCP Server — Live Cluster Tools:**

The MCP server exposes Kubernetes and platform operations as tools that the AI can call autonomously:

| Tool | What it does |
|---|---|
| `get_pod_logs` | Fetch logs from a specific pod/container |
| `get_pod_events` | Fetch K8s events for a pod |
| `describe_resource` | kubectl describe on any resource |
| `get_deployment_status` | Replica status, rollout history |
| `get_argocd_sync_status` | ArgoCD app health and sync state |
| `get_crossplane_claim_status` | Crossplane resource provisioning status |
| `query_prometheus` | Run PromQL queries for metrics |
| `get_kyverno_violations` | Policy violations for a namespace |
| `get_nsg_flow_logs` | Network security group flow decisions |

```python
# Example MCP tool definition
@mcp.tool()
async def get_pod_logs(namespace: str, pod: str, lines: int = 100) -> str:
    """Fetch recent logs from a Kubernetes pod."""
    result = subprocess.run(
        ["kubectl", "logs", pod, "-n", namespace, f"--tail={lines}"],
        capture_output=True, text=True
    )
    return result.stdout
```

**RAG Engine — Knowledge-Aware Diagnosis:**

Platform documentation, runbooks, and past incident reports are chunked, embedded, and stored in a vector database. The AI searches them for context-relevant guidance.

```
Indexed sources:
  → Backstage TechDocs (platform docs, onboarding guides)
  → Runbooks (troubleshooting playbooks per service)
  → Past incident reports (what broke, root cause, fix)
  → Kubernetes docs (error reference)
  → Crossplane/ArgoCD docs (common issues)
```

```python
# RAG indexing pipeline
from chromadb import Client
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("all-MiniLM-L6-v2")
db = Client()
collection = db.get_or_create_collection("platform-docs")

# Chunk and embed documents
for doc in load_docs("docs/"):
    chunks = chunk_text(doc.content, max_tokens=500)
    embeddings = model.encode(chunks)
    collection.add(
        documents=chunks,
        embeddings=embeddings,
        ids=[f"{doc.name}_{i}" for i in range(len(chunks))]
    )
```

```python
# RAG search at query time
def search_runbooks(query: str, top_k: int = 3) -> list[str]:
    results = collection.query(
        query_embeddings=model.encode([query]),
        n_results=top_k
    )
    return results["documents"][0]
```

**CLI Usage:**

```bash
# Diagnose a failing pod
idp-debug --namespace orders-dev --pod orders-service-xyz

# Diagnose with specific context
idp-debug --namespace orders-dev --issue "connection timeout to postgres"

# List available MCP tools
idp-debug --list-tools
```

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
├── tools/                            # AI debugging layer
│   ├── mcp-server/                   # MCP server (cluster tools)
│   │   ├── server.py                 # MCP protocol handler
│   │   ├── requirements.txt
│   │   └── tools/
│   │       ├── kubectl.py            # Pod logs, events, describe
│   │       ├── argocd.py             # Sync status, app health
│   │       ├── prometheus.py         # PromQL queries
│   │       └── crossplane.py         # Claim status
│   ├── rag/                          # RAG engine (knowledge retrieval)
│   │   ├── index.py                  # Embed and index docs
│   │   ├── search.py                 # Semantic search
│   │   └── requirements.txt
│   └── ai-debug/                     # CLI entrypoint
│       ├── cli.py                    # Ties MCP + RAG + Claude API
│       └── requirements.txt
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

### Phase 6 — AI Debugging Layer (Week 9-10)

**Goal:** AI-powered issue diagnosis using live cluster data + platform knowledge

- [ ] MCP Server: Python server exposing kubectl, ArgoCD, Prometheus as MCP tools
- [ ] MCP Tools: get_pod_logs, get_pod_events, describe_resource, get_argocd_sync_status, query_prometheus
- [ ] AI Debug CLI: Claude API integration, calls MCP tools autonomously based on developer's question
- [ ] RAG: Index platform docs, runbooks, and troubleshooting guides using ChromaDB + sentence-transformers
- [ ] RAG Search: Semantic search over indexed docs, injected as context into Claude prompts
- [ ] End-to-end flow: `idp-debug --namespace orders-dev --pod orders-xyz` → MCP pulls data → RAG adds context → Claude diagnoses

**Milestone:** Run `idp-debug` on a CrashLoopBackOff pod → AI pulls logs via MCP, finds OOM error, searches runbook via RAG, recommends increasing memory limit with the exact Helm values change.

---

## Future Enhancements

- [ ] **Multi-cluster:** ArgoCD managing dev + staging + prod clusters
- [ ] **Preview environments:** PR creates ephemeral namespace, destroyed on merge
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
- `python` >= 3.10
- GitHub account + personal access token
- Anthropic API key (for AI debug CLI)

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

# Setup AI debug tools
cd tools/rag && pip install -r requirements.txt
python index.py                    # Index platform docs
cd ../mcp-server && pip install -r requirements.txt
cd ../ai-debug && pip install -r requirements.txt

# Test AI debug CLI
idp-debug --list-tools
```

---

## Project Vision

This platform demonstrates the shift from **"DevOps as a service desk"** to **"DevOps as a product team"** — building the platform that empowers developers to self-serve while maintaining governance, security, and cost control.

Built with the tools that define Platform Engineering in 2026: **Backstage, Crossplane, ArgoCD, Kyverno, MCP, RAG**.

---

## References

- [Backstage.io](https://backstage.io/)
- [Crossplane Docs](https://docs.crossplane.io/)
- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Kyverno Docs](https://kyverno.io/docs/)
- [Azure AKS Docs](https://learn.microsoft.com/en-us/azure/aks/)
- [Platform Engineering Maturity Model](https://tag-app-delivery.cncf.io/whitepapers/platform-eng-maturity-model/)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [ChromaDB](https://docs.trychroma.com/)
- [Anthropic Claude API](https://docs.anthropic.com/)
