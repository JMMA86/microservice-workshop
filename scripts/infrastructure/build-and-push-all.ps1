# PowerShell script to build and push all microservices to Azure Container Registry

Set-Location (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ../..)

# Get ACR name from config file
echo "Reading ACR name from aks-acr-config.cfg..."
$configPath = "infrastructure/terraform/environments/dev/aks-acr-config.cfg"
$acrName = Select-String -Path $configPath -Pattern 'acr_registry_name' | ForEach-Object { $_.Line.Split('=')[1].Trim(' "') }
if (-not $acrName) {
    Write-Error "ACR name not found in $configPath"
    exit 1
}

$acrLoginServer = "$acrName.azurecr.io"
echo "Logging in to $acrLoginServer..."
az acr login --name $acrName

# Build and push each microservice
echo "Building and pushing microservices..."
$microservicesPath = "microservices"
Get-ChildItem -Path $microservicesPath -Directory | ForEach-Object {
    $serviceName = $_.Name.Trim()
    echo "Detected service: '$serviceName'"
    $dockerfilePath = Join-Path $_.FullName "Dockerfile"
    if (Test-Path $dockerfilePath) {
        if ([string]::IsNullOrWhiteSpace($serviceName)) {
            echo "Service name is empty, skipping."
        } else {
            $imageTag = ("{0}/{1}:latest" -f $acrLoginServer, $serviceName)
            echo "Building $serviceName as $imageTag..."
            docker build -t $imageTag $_.FullName
            echo "Pushing $imageTag..."
            docker push $imageTag
        }
    } else {
        echo "No Dockerfile found for $serviceName, skipping."
    }
}
echo "All done!"
