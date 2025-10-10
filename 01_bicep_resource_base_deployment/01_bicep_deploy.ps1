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
#$AzureTenantID = $env:AZURE_TENANT_ID
#$AzureSubscriptionID = $env:AZURE_SUBSCRIPTION_ID
$AzureResourceGroupName = $env:AZURE_RESOURCE_GROUP_NAME
$AzureRegion = $env:AZURE_DEPLOYMENT_REGION

if (-not $AzureResourceGroupName) {
    Write-Error "Environment variable AZURE_RESOURCE_GROUP_NAME is not set."
    exit 1
}
if (-not $AzureRegion) {
    Write-Error "Environment variable AZURE_REGION is not set."
    exit 1
}

#$bicepFileName = "02_vnet_snet.bicep"
#$bicepFileName = "03_privatedns.bicep"
#$bicepFileName = "04_azureloganalytics.bicep"
#$bicepFileName = "05_azureFoundry.bicep"
#$bicepFileName = "06_vm.bicep"
$bicepFileName = "07_vpngateway.bicep"

# Derive deployment name from the Bicep file name and adds the timestamp
$bicepDeploymentName = $bicepFileName.Split(".")[0] + "-deployment-" + (Get-Date -Format "yyyyMMddHHmmss")  

# Check if the resource group exists and deploy accordingly
#$rgExists = az group exists --name $azResourceGroup
$rgExists = az group exists --name $AzureResourceGroupName

if ($rgExists -eq $true) {
    # Deploy the Bicep file if resource group exists
    # Write-Host "Resource group $azResourceGroup exists. Proceeding with deployment..." -ForegroundColor Green
    Write-Host "Resource group $AzureResourceGroupName exists. Proceeding with deployment..." -ForegroundColor Green
    az deployment group create `
        --resource-group $AzureResourceGroupName `
        --template-file $bicepFileName `
        --name $bicepDeploymentName `
        --mode Incremental `
        --verbose
} else {
    # Stop the script if resource group does not exist
    Write-Host "Resource group $AzureResourceGroupName does not exist. Please run 00_azure_login.ps1 first to create the resource group." -ForegroundColor Red
    exit
}

# List resources in the resource group after deployment
az resource list --resource-group $AzureResourceGroupName -o table