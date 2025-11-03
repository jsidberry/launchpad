# Variables
SERVICE_CONNECTION_NAME="azure-connection-arm"
SERVICE_PRINCIPAL_ID=$(jq -r .clientId azuredevops-sp.json)
SERVICE_PRINCIPAL_KEY=$(jq -r .clientSecret azuredevops-sp.json)
TENANT_ID=$(jq -r .tenantId azuredevops-sp.json)
SUBSCRIPTION_ID=$(jq -r .subscriptionId azuredevops-sp.json)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

# Create Service Connection (unapproved)
az devops service-endpoint azurerm create \
  --name "$SERVICE_CONNECTION_NAME" \
  --azure-rm-service-principal-id "$SERVICE_PRINCIPAL_ID" \
  --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
  --azure-rm-subscription-name "$SUBSCRIPTION_NAME" \
  --azure-rm-tenant-id "$TENANT_ID" \
  --azure-rm-service-principal-key "$SERVICE_PRINCIPAL_KEY"