#!/usr/bin/env bash
#
# One-time bootstrap of Azure resources the GitHub Actions pipeline needs:
#   1. Resource group + Storage account + container for Terraform remote state
#   2. User-Assigned Managed Identity for GitHub OIDC auth
#   3. Role assignments (Contributor + UAA + Storage Blob Data Contributor)
#   4. Federated credentials trusting this GitHub repo
#
# Run once per Azure subscription, after `az login`.
#
# Usage:
#   ./scripts/bootstrap-pipeline.sh
#
# Output: prints the values you must paste into GitHub repo
#         Settings -> Secrets and variables -> Actions -> Variables tab.

set -euo pipefail

# ---------- Config (edit if you want different names) -----------------------
LOCATION="eastus"
STATE_RG="rg-tfstate"
STATE_SA="stidptfstate$(date +%s | tail -c 6)"   # globally unique; reused if exists
STATE_CONTAINER="tfstate"

MI_NAME="mi-github-idp-pipeline"
MI_RG="$STATE_RG"

REPO="Pritam224/Internal-developer-Platform"
OWNER_EMAIL="pritam.singh@thoughtworks.com"
PROJECT_TAG="internal-developer-platform"

# ---------- Pre-flight -------------------------------------------------------
echo "==> Checking az CLI..."
command -v az >/dev/null || { echo "az CLI not installed"; exit 1; }

echo "==> Confirming subscription..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_NAME=$(az account show --query name -o tsv)
echo "    Subscription: $SUB_NAME ($SUBSCRIPTION_ID)"
echo "    Tenant:       $TENANT_ID"
read -p "==> Proceed with bootstrap on this subscription? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

# ---------- 1. Storage for Terraform state ----------------------------------
echo "==> [1/4] Creating state resource group ($STATE_RG)..."
az group create -n "$STATE_RG" -l "$LOCATION" \
  --tags "owners=$OWNER_EMAIL" "project=$PROJECT_TAG" >/dev/null

# Re-use an existing state SA in this RG if present; otherwise create one.
EXISTING_SA=$(az storage account list -g "$STATE_RG" --query "[?starts_with(name, 'stidptfstate')].name | [0]" -o tsv 2>/dev/null || true)
if [[ -n "$EXISTING_SA" ]]; then
  STATE_SA="$EXISTING_SA"
  echo "==> Re-using existing storage account: $STATE_SA"
else
  echo "==> Creating storage account ($STATE_SA)..."
  az storage account create \
    -n "$STATE_SA" -g "$STATE_RG" -l "$LOCATION" \
    --sku Standard_LRS \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --tags "owners=$OWNER_EMAIL" "project=$PROJECT_TAG" >/dev/null
fi

echo "==> Ensuring container '$STATE_CONTAINER' exists..."
az storage container create \
  --account-name "$STATE_SA" \
  -n "$STATE_CONTAINER" \
  --auth-mode login >/dev/null || true

# ---------- 2. User-Assigned Managed Identity -------------------------------
echo "==> [2/4] Creating managed identity ($MI_NAME)..."
az identity create -n "$MI_NAME" -g "$MI_RG" -l "$LOCATION" \
  --tags "owners=$OWNER_EMAIL" "project=$PROJECT_TAG" >/dev/null

MI_CLIENT_ID=$(az identity show -n "$MI_NAME" -g "$MI_RG" --query clientId -o tsv)
MI_PRINCIPAL_ID=$(az identity show -n "$MI_NAME" -g "$MI_RG" --query principalId -o tsv)

# ---------- 3. Role assignments ---------------------------------------------
echo "==> [3/4] Assigning roles to MI ($MI_CLIENT_ID)..."

assign_role() {
  local role="$1" scope="$2"
  echo "    -> $role on $scope"
  az role assignment create \
    --assignee-object-id "$MI_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "$role" \
    --scope "$scope" >/dev/null 2>&1 || echo "       (already assigned)"
}

SUB_SCOPE="/subscriptions/$SUBSCRIPTION_ID"
STATE_SA_ID=$(az storage account show -n "$STATE_SA" -g "$STATE_RG" --query id -o tsv)

# Broad: Contributor for creating/destroying all resources
assign_role "Contributor" "$SUB_SCOPE"

# Needed because AKS module creates a role assignment (AcrPull)
assign_role "User Access Administrator" "$SUB_SCOPE"

# Read/write state blobs
assign_role "Storage Blob Data Contributor" "$STATE_SA_ID"

# ---------- 4. Federated credentials ----------------------------------------
echo "==> [4/4] Adding federated credentials for $REPO..."

add_fed_cred() {
  local name="$1" subject="$2"
  echo "    -> $name (subject: $subject)"
  az identity federated-credential create \
    -n "$name" \
    --identity-name "$MI_NAME" \
    -g "$MI_RG" \
    --issuer https://token.actions.githubusercontent.com \
    --subject "$subject" \
    --audiences api://AzureADTokenExchange >/dev/null 2>&1 \
    || echo "       (already exists)"
}

add_fed_cred "github-main"     "repo:$REPO:ref:refs/heads/main"
add_fed_cred "github-pr"       "repo:$REPO:pull_request"
add_fed_cred "github-env-dev"  "repo:$REPO:environment:dev"
add_fed_cred "github-env-prod" "repo:$REPO:environment:prod"

# ---------- Summary ----------------------------------------------------------
cat <<EOF

============================================================
  Bootstrap complete. Set these in your GitHub repo at:
    Settings -> Secrets and variables -> Actions -> Variables
============================================================

  AZURE_CLIENT_ID         = $MI_CLIENT_ID
  AZURE_TENANT_ID         = $TENANT_ID
  AZURE_SUBSCRIPTION_ID   = $SUBSCRIPTION_ID
  TFSTATE_RG              = $STATE_RG
  TFSTATE_SA              = $STATE_SA
  TFSTATE_CONTAINER       = $STATE_CONTAINER

  Then in GitHub: Settings -> Environments -> create 'dev' and 'prod'
  (add Required reviewers on 'prod' for safety).

  Test the pipeline:
    Actions tab -> Infra -> Run workflow
    -> environment=dev, action=plan
============================================================
EOF
