# Variables
SUBSCRIPTION_ID="<your-subscription-id>"
SERVICE_PRINCIPAL_NAME="sp-name"  # example: devops-sp-connection
RESOURCE_GROUP="<target-resource-group>"  # Optional if assigning at subscription level

# Create SP with a Contributor role on a resource group
az ad sp create-for-rbac \
  --name $SERVICE_PRINCIPAL_NAME \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth > specific-purpose-sp-filename.json  # example azuredevops-sp.json