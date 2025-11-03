#!/bin/bash
set -e

# Load environment variables from .env if it exists
if [ -f .env ]; then
  # Option 1: Safest way – only load valid variable lines
  export $(grep -v '^#' .env | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# Variables
SUBSCRIPTION_NAME=$AZ_SUBSCRIPTION_NAME
SERVICE_PRINCIPAL_NAME=$AZ_SERVICE_PRINCIPAL_NAME  # example: devops-sp-connection
RESOURCE_GROUP=$AZ_RESOURCE_GROUP  # Optional if assigning at subscription level

# get subecription_id fromt he subscription_name
SUBSCRIPTION_ID=$(az account list --query "[?name=='${SUBSCRIPTION_NAME}'].id" -o tsv)


# Create SP with a Contributor role on a resource group
az ad sp create-for-rbac \
  --name $SERVICE_PRINCIPAL_NAME \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth > azuredevops-sp.json  # example filename
