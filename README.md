# Internal Developer Platform (IDP)

A Kubernetes-based Internal Developer Platform on Azure (AKS). Provides self-service deployment and infrastructure via GitOps, with a developer portal on top.

> **Status:** early MVP — infra modules + ArgoCD + a sample microservice chart are live. Higher-level components (ingress, observability, SSO, portal) are upcoming.

---

## Goals

Give developers a paved road for:
- Deploying microservices to AKS without writing custom YAML
- Pulling secrets from Azure Key Vault without storing credentials
- Observing their services (metrics, logs, traces) in one place
- Scaffolding new services from a template
- Knowing where everything lives via a single portal

While platform engineers retain control of: security baselines, networking, image registry, identity, cost.

---

## Tech stack

| Layer | Tool |
|---|---|
| Cloud | Azure (AKS, ACR, Key Vault, PostgreSQL) |
| IaC | Terraform (azurerm v4.1.0) |
| GitOps | ArgoCD |
| Packaging | Helm |
| Service language | FastAPI (Python) |
| Observability | Prometheus + Grafana |
| Identity / SSO | Keycloak |
| Developer portal | Backstage |
| CI | GitHub Actions |

**Explicitly out of scope:** Crossplane (Terraform handles infra). Istio (deferred — may add for mesh later).

---

## Architecture (current + planned)

```
Developer commits  →  GitHub Actions  →  ACR (image)
                                            │
GitHub repo (this one) ────────────────►  ArgoCD  ──► AKS
                                            │
                                            └──► applies Helm charts
                                                  + raw K8s manifests
                                                  from infra-manifest/
```

Behind the scenes:
- **Terraform** provisions AKS, ACR, Key Vault, VNet
- **AKS kubelet identity** has `AcrPull` on ACR (no docker auth secrets)
- **AKS OIDC issuer** enabled — workload identity for pods to talk to Azure
- **ArgoCD** root Application points at `infra-manifest/<env>/` → discovers everything from git

---

## Repo layout

```
├── infra/                         # Terraform
│   ├── modules/
│   │   ├── network/               # RG, VNet, subnets, NSG
│   │   ├── aks/                   # Cluster + autoscaled app pool + OIDC + AcrPull
│   │   ├── acr/                   # Registry (Premium SKU + private endpoint optional)
│   │   └── keyvault/              # Key Vault with optional purge protection
│   └── environments/
│       ├── dev/                   # rg-app-dev, applied
│       └── prod/                  # rg-idp-prod, scaffolded
│
├── argocd/                        # ArgoCD bootstrap
│   ├── values.yaml                # vendored chart defaults (gitignored)
│   ├── dev/
│   │   ├── values.yaml            # dev overrides (resources, dex off, repo)
│   │   └── root-app.yaml          # bootstrap pointer: watch infra-manifest/dev/
│   └── prod/
│       ├── values.yaml            # HA: 2 replicas everywhere, redis-ha
│       └── root-app.yaml          # bootstrap pointer: watch infra-manifest/prod/
│
└── infra-manifest/                # what ArgoCD syncs
    ├── dev/
    │   ├── backend-app.yaml       # Application CRD → backend chart
    │   └── ubuntu-pod.yaml        # sample raw manifest
    ├── prod/
    └── helm/
        └── backend/               # generic backend microservice chart
```

---

## Bootstrap (per cluster)

After `terraform apply` makes the AKS cluster available:

```bash
# 1. Install ArgoCD
helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  -f argocd/values.yaml -f argocd/dev/values.yaml

# 2. Tell ArgoCD what to watch
kubectl apply -f argocd/dev/root-app.yaml

# 3. Walk away — every subsequent change flows through git commits
```

For prod, swap `dev` → `prod` in both commands.

---

## What's built so far

- [x] Terraform: network + AKS + ACR + Key Vault modules
- [x] Dev environment applied
- [x] Prod environment scaffolded (apply pending)
- [x] AKS kubelet identity → ACR `AcrPull` role
- [x] AKS OIDC issuer enabled (workload identity prerequisite)
- [x] ArgoCD installed on dev with clean chart/root separation
- [x] Generic backend microservice Helm chart (Deployment, Service, HPA, Ingress, optional PVC)
- [x] Backend chart wired into ArgoCD via child Application

## What's next

- [ ] Replace nginx placeholder with a real FastAPI service (Dockerfile → ACR → chart)
- [ ] NGINX Ingress + cert-manager (stop port-forward, real URLs + TLS)
- [ ] Remote Terraform state (Azure Storage backend)
- [ ] External Secrets Operator + Workload Identity (Azure KV → K8s secrets without credentials)
- [ ] GitHub Actions CI: build image, push to ACR, bump chart values
- [ ] Prometheus + Grafana (observability)
- [ ] Keycloak (SSO for ArgoCD + Backstage + Grafana)
- [ ] Backstage (developer portal — service catalog, templates, integrations)
- [ ] Optional later: Istio / service mesh

---

## Owner

Pritam Singh (`pritam.singh@thoughtworks.com`) — ThoughtWorks Azure subscription. Subscription enforces mandatory `owners` and `project` tags on every Resource Group (handled in the network module).

---

## See also

- `docs/learnings.md` — running log of concepts learned and problems solved
- `CLAUDE.md` — concise context for AI coding assistance
