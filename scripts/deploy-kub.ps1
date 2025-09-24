# Load environment variables
$env:AZURE_CLIENT_ID = "ea9c5569-68db-48c8-b932-1041f724b986"
$env:AZURE_CLIENT_SECRET = "De18Q~WCCbIbMGc73Wfs~kDswtvIlVlDGTwnBcEJ"
$env:AZURE_TENANT_ID = "e994072b-523e-4bfe-86e2-442c5e10b244"
$env:AZURE_SUBSCRIPTION_ID = "f3232678-472a-4a87-b56e-c8cbfa96666e"

$resourceGroup = "msworkshop1-dev-rg"
$aksName = "msworkshop1-dev-aks"

# Save original location
$OriginalLocation = Get-Location

# Script and kustomize directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$KustomizeDir = Join-Path $ScriptDir "..\deployment\kubernetes\dev"
$KustomizeDir = Resolve-Path $KustomizeDir

try {
    Write-Host "`n=== LOGIN AZURE SERVICE PRINCIPAL ==="
    az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en az login"
        exit 1
    }

    Write-Host "`n=== SELECCIONANDO SUBSCRIPCION ==="
    az account set --subscription $env:AZURE_SUBSCRIPTION_ID
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en az account set"
        exit 1
    }

    Write-Host "`n=== OBTENIENDO CREDENCIALES DE AKS ==="
    az aks get-credentials --resource-group $resourceGroup --name $aksName --overwrite-existing
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en az aks get-credentials"
        exit 1
    }

    Write-Host "`n=== DESPLEGANDO MANIFIESTOS KUSTOMIZE ==="
    Set-Location $KustomizeDir
    kubectl apply -k .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en kubectl apply -k ."
        exit 1
    }

    Write-Host "`n=== ESPERANDO QUE TODOS LOS PODS ESTÉN RUNNING ==="
    $maxAttempts = 30
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $podsOutput = kubectl get pods --no-headers
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Error al obtener el estado de los pods."
            exit 1
        }
        $notReady = $false
        foreach ($line in $podsOutput) {
            $columns = $line -split '\s+'
            if ($columns.Length -ge 3) {
                $readyParts = $columns[1] -split '/'
                $ready = [int]$readyParts[0]
                $total = [int]$readyParts[1]
                $status = $columns[2]
                if ($ready -ne $total -or $status -ne "Running") {
                    $notReady = $true
                    break
                }
            }
        }
        if (-not $notReady) {
            Write-Host "\nTodos los pods están en estado Running."
            break
        }
        Start-Sleep -Seconds 1
        $attempt++
    }
    if ($notReady) {
        Write-Error "No todos los pods están en estado Running tras esperar."
        exit 1
    }

    Write-Host "`n=== REINICIANDO PODS ==="
    kubectl rollout restart deployment auth-api frontend log-message-processor todos-api users-api zipkin redis
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en kubectl rollout restart"
        exit 1
    }

    Write-Host "`nDespliegue exitoso."
    exit 0
}
finally {
    Set-Location $OriginalLocation
}
