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
ORGANIZATION=$ADO_ORG_NAME
PROJECT_NAME=$ADO_PROJECT_NAME
PROJECT_DESCRIPTION=$ADO_PROJECT_DESCRIPTION
PROCESS_TEMPLATE=$ADO_PROCESS_TEMPLATE  # Options: Agile, Basic, Scrum, CMMI
VISIBILITY=$ADO_VISIBILITY       # Options: private, public

# Check if Azure DevOps CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if devops extension is installed
if ! az extension list | grep -q "azure-devops"; then
    echo "Installing Azure DevOps extension..."
    az extension add --name azure-devops
fi

# Login to Azure (if not already logged in)
echo "Checking Azure login status..."
az account show &> /dev/null || az login

# Set default organization
az devops configure --defaults organization=https://dev.azure.com/$ORGANIZATION

# Create the project
echo "Creating Azure DevOps project: $PROJECT_NAME"
az devops project create \
    --name "$PROJECT_NAME" \
    --description "$PROJECT_DESCRIPTION" \
    --process "$PROCESS_TEMPLATE" \
    --visibility "$VISIBILITY" \
    --org https://dev.azure.com/$ORGANIZATION

echo "Project '$PROJECT_NAME' created successfully!"

# Optional: Set this as default project
az devops configure --defaults project="$PROJECT_NAME"

# Display project details
az devops project show --project "$PROJECT_NAME" --org https://dev.azure.com/$ORGANIZATION