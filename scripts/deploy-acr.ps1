# Crear imágenes Docker para los microservicios en ACR
$env:AZURE_CLIENT_ID = "ea9c5569-68db-48c8-b932-1041f724b986"
$env:AZURE_CLIENT_SECRET = "De18Q~WCCbIbMGc73Wfs~kDswtvIlVlDGTwnBcEJ"
$env:AZURE_TENANT_ID = "e994072b-523e-4bfe-86e2-442c5e10b244"
$env:AZURE_SUBSCRIPTION_ID = "f3232678-472a-4a87-b56e-c8cbfa96666e"

# Guardar ubicación original
$OriginalLocation = Get-Location

# Obtener ruta base del workspace
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$WorkspaceDir = Resolve-Path (Join-Path $ScriptDir "..")

# Variables para el ACR
$acrName = "msworkshop1devacr"
$acrLoginServer = "$acrName.azurecr.io"

try {
    Write-Host "`n=== LOGIN AZURE SERVICE PRINCIPAL ==="
    az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en az login"
        exit 1
    }

    Write-Host "`n=== LOGGING IN TO AZURE CONTAINER REGISTRY ==="
    az acr login --name $acrName
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error logging in to ACR."
        exit 1
    }

    Write-Host "`n=== BUILDING AND PUSHING DOCKER IMAGES ==="
    $images = @(
        @{ name = "log-message-processor"; path = Join-Path $WorkspaceDir "microservices/log-message-processor" },
        @{ name = "auth-api"; path = Join-Path $WorkspaceDir "microservices/auth-api" },
        @{ name = "frontend"; path = Join-Path $WorkspaceDir "microservices/frontend" },
        @{ name = "todos-api"; path = Join-Path $WorkspaceDir "microservices/todos-api" },
        @{ name = "users-api"; path = Join-Path $WorkspaceDir "microservices/users-api" }
    )

    foreach ($img in $images) {
        $localTag = "$($img.name):latest"
        $acrTag = "$acrLoginServer/$($img.name):latest"
        try {
            if ($img.path -ne "") {
                docker build -t $localTag -f "$($img.path)/Dockerfile" $($img.path)
            } else {
                docker pull $($img.baseImage)
                docker tag $($img.baseImage) $localTag
            }
            docker tag $localTag $acrTag
            docker push $acrTag
        }
        catch {
            Write-Error "Error building/tagging/pushing $($img.name): $_"
            exit 1
        }
    }

    Write-Host "`nDocker Images built and pushed to ACR successfully."
    exit 0
}
finally {
    Set-Location $OriginalLocation
}
