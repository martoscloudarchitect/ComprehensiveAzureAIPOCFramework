# Function to load .env file
function Load-DotEnv {
    param (
        [string]$Path
    )
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]*)\s*=\s*(.*)\s*$") {
                $name = $matches[1]
                $value = $matches[2]
                [System.Environment]::SetEnvironmentVariable($name, $value)
            }
        }
    } else {
        Write-Error "The .env file was not found at path: $Path"
        exit 1
    }
}

# Load environment variables from .env file
$envFilePath = ".env"
Load-DotEnv -Path $envFilePath

# Retrieve Environment Variables
$AzureTenantID = $env:AZURE_TENANT_ID
$AzureSubscriptionID = $env:AZURE_SUBSCRIPTION_ID
$AzureResourceGroupName = $env:AZURE_RESOURCE_GROUP_NAME
$AzureRegion = $env:AZURE_DEPLOYMENT_REGION

# Check if the environment variables are set
if (-not $AzureTenantID) {
    Write-Error "Environment variable AZURE_TENANT_ID is not set."
    exit 1
}

if (-not $AzureSubscriptionID) {
    Write-Error "Environment variable AZURE_SUBSCRIPTION_ID is not set."
    exit 1
}
if (-not $AzureResourceGroupName) {
    Write-Error "Environment variable AZURE_RESOURCE_GROUP_NAME is not set."
    exit 1
}
if (-not $AzureRegion) {
    Write-Error "Environment variable AZURE_REGION is not set."
    exit 1
}

# Connect to Azure
az login --tenant $AzureTenantID
# Set the default subscription
az account set --subscription $AzureSubscriptionID

## Create a resource group
#az group create `
#    --name $AzureResourceGroupName `
#    --location $AzureRegion

# Check if the resource group exists, if not create it, if it does exist, inform that connection to tenant is successful and resource group exists
$rgExists = az group exists --name $AzureResourceGroupName
if ($rgExists -eq $false) {
    az group create --name $AzureResourceGroupName --location $AzureRegion
    Write-Host "Resource Group $AzureResourceGroupName created in tenant $AzureTenantID." -ForegroundColor Green
} else {
    Write-Host "Connection to tenant $AzureTenantID is successful and resource group $AzureResourceGroupName already exists." -ForegroundColor Yellow
}


az resource list --resource-group $AzureResourceGroupName -o table