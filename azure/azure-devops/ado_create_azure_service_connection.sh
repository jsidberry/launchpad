#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
# create_azure_service_connection.sh
# Automates creation of Azure DevOps ARM Service Connection
# ---------------------------------------------------------
# REQUIREMENTS:
# - Azure CLI (az)
# - Azure DevOps CLI extension (az extension add --name azure-devops)
# - jq installed
#
# USAGE:
# ./create_azure_service_connection.sh \
#   "<ORG_URL>" "<PROJECT_NAME>" "<SERVICE_CONNECTION_NAME>" \
#   "<SUBSCRIPTION_NAME>" "<RESOURCE_GROUP>" "<SP_NAME>"
# ---------------------------------------------------------

ORG_URL="${1:?Organization URL required (e.g. https://dev.azure.com/myorg)}"
PROJECT_NAME="${2:?Project name required}"
SERVICE_CONNECTION_NAME="${3:?Service connection name required}"
SUBSCRIPTION_NAME="${4:?Subscription name required}"
RESOURCE_GROUP="${5:?Resource group name required}"
SERVICE_PRINCIPAL_NAME="${6:?Service principal name required}"

# get subecription_id fromt he subscription_name
SUBSCRIPTION_ID=$(az account list --query "[?name=='${SUBSCRIPTION_NAME}'].id" -o tsv)

# Optional role
AZURE_ROLE=${AZURE_ROLE:-"Contributor"}

echo ">>> Ensuring Azure DevOps CLI extension is installed..."
az extension add --name azure-devops --only-show-errors 2>/dev/null || true

# ---------------------------------------------------------
# OPTIONAL: Ensure the project exists
# ---------------------------------------------------------
echo ">>> Checking if Azure DevOps project '$PROJECT_NAME' exists..."
PROJECT_EXISTS=$(az devops project list --query "value[?name=='$PROJECT_NAME'].name" -o tsv || true)

if [[ -z "$PROJECT_EXISTS" ]]; then
  echo ">>> Creating new Azure DevOps project: $PROJECT_NAME"
  az devops project create --name "$PROJECT_NAME" --visibility private --process Basic \
    --organization "$ORG_URL" --only-show-errors
else
  echo ">>> Project already exists: $PROJECT_NAME"
fi

# ----------------
# set ADO defaults
# ----------------

echo ">>> Setting Azure DevOps defaults..."
az devops configure --defaults organization="$ORG_URL" project="$PROJECT_NAME"

# ---------------------------------------------------------
# Create Service Principal (or reuse existing)
# ---------------------------------------------------------
echo ">>> Checking for existing Service Principal..."
SP_EXISTS=$(az ad sp list --display-name "$SERVICE_PRINCIPAL_NAME" --query "[].appId" -o tsv)

if [[ -z "$SP_EXISTS" ]]; then
  echo ">>> Creating new Service Principal: $SERVICE_PRINCIPAL_NAME"
  az ad sp create-for-rbac \
    --name "$SERVICE_PRINCIPAL_NAME" \
    --role "$AZURE_ROLE" \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
    --sdk-auth > azuredevops-sp.json
else
  echo ">>> Service Principal already exists. Fetching credentials..."
  az ad sp credential reset --name "$SERVICE_PRINCIPAL_NAME" --credential-description "DevOpsBootstrap" --sdk-auth > azuredevops-sp.json
fi

SERVICE_PRINCIPAL_ID=$(jq -r .clientId azuredevops-sp.json)
SERVICE_PRINCIPAL_KEY=$(jq -r .clientSecret azuredevops-sp.json)
TENANT_ID=$(jq -r .tenantId azuredevops-sp.json)
# SUBSCRIPTION_NAME=$(az account show --subscription "$SUBSCRIPTION_ID" --query name -o tsv)



# ---------------------------------------------------------
# Create or update Service Connection
# ---------------------------------------------------------
echo ">>> Checking if Service Connection already exists..."
EXISTING_ID=$(az devops service-endpoint list \
  --query "[?name=='$SERVICE_CONNECTION_NAME'].id" -o tsv || true)

if [[ -n "$EXISTING_ID" ]]; then
  echo ">>> Service Connection already exists: $SERVICE_CONNECTION_NAME ($EXISTING_ID)"
else
  echo ">>> Creating Azure Resource Manager Service Connection..."
  az devops service-endpoint azurerm create \
    --name "$SERVICE_CONNECTION_NAME" \
    --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" \
    --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
    --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
    --azure-rm-tenant-id "$TENANT_ID" \
    --only-show-errors > /dev/null

  echo ">>> Service Connection created."
fi

# ---------------------------------------------------------
# Step 3. Approve and enable the Service Connection
# ---------------------------------------------------------
SERVICE_CONNECTION_ID=$(az devops service-endpoint list \
  --query "[?name=='$SERVICE_CONNECTION_NAME'].id" -o tsv)

echo ">>> Approving and enabling Service Connection for all pipelines..."
az devops service-endpoint update \
  --id "$SERVICE_CONNECTION_ID" \
  --enable-for-all true \
  --only-show-errors > /dev/null

# ---------------------------------------------------------
# Done
# ---------------------------------------------------------
echo "✅ Azure DevOps Service Connection successfully created and approved!"
echo "---------------------------------------------------------"
echo "Organization:  $ORG_URL"
echo "Project:       $PROJECT_NAME"
echo "Service Conn.: $SERVICE_CONNECTION_NAME"
echo "Subscription:  $SUBSCRIPTION_NAME"
echo "Tenant ID:     $TENANT_ID"
echo "Service Princ.:$SERVICE_PRINCIPAL_NAME"
echo "---------------------------------------------------------"
echo "Service Principal credentials stored in: ./azuredevops-sp.json"
echo "---------------------------------------------------------"