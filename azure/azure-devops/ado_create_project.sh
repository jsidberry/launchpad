#!/bin/bash
set -e

# Variables
ORGANIZATION="your-org-name"
PROJECT_NAME="SRE-Pipelines"
PROJECT_DESCRIPTION="SRE automation and deployment pipelines"
PROCESS_TEMPLATE="Agile"  # Options: Agile, Basic, Scrum, CMMI
VISIBILITY="private"       # Options: private, public

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