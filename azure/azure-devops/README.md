# Azure DevOps

bootstrap

REMEMBER: all values for variables (especially sensitive values) are pulled from the `.env` file that is provided outside of this repo and kept somewhere secure. Using local Environment Variables is a good practice widely used; however, it is tedious to maintain across platforms, so look for and will try other methods.

create a Project in Azure DevOps

Steps:
- create a service principal that will act as the user

## Pre-requisites
You need to have the values for the following variables in the script.

### Create a Service Principal (Programmatically)
Execute `create_service_principal.sh`. Output file `azuredevops-sp.json` contains credentials in JSON form to be used later.
```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "...",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  ...
}
```

### Variables
ORGANIZATION="your-org-name"
PROJECT_NAME="your-project-nams" # example: SRE-infrastructure
PROJECT_DESCRIPTION="SRE automation and deployment pipelines" # example
PROCESS_TEMPLATE="Agile"  # Options: Agile, Basic, Scrum, CMMI
VISIBILITY="private"      # Options: private, public
