param(
    [ValidateSet("all", "bootstrap", "dev")]
    [string]$Deploy = "all"
)

# Set variables
$subscriptionId = "f3232678-472a-4a87-b56e-c8cbfa96666e"
$env:AZURE_CLIENT_ID = "ea9c5569-68db-48c8-b932-1041f724b986"
$env:AZURE_CLIENT_SECRET = "De18Q~WCCbIbMGc73Wfs~kDswtvIlVlDGTwnBcEJ"
$env:AZURE_TENANT_ID = "e994072b-523e-4bfe-86e2-442c5e10b244"
$env:AZURE_SUBSCRIPTION_ID = "f3232678-472a-4a87-b56e-c8cbfa96666e"

# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$bootstrapDir = Resolve-Path (Join-Path $ScriptDir "..\infrastructure\terraform\bootstrap")
$devEnvDir = Resolve-Path (Join-Path $ScriptDir "..\infrastructure\terraform\environments\dev")
$backendConfig = "backend-config.hcl"

# Save the original location
$OriginalLocation = Get-Location

try {
    Write-Host "`n=== LOGIN AZURE SERVICE PRINCIPAL ==="
    az login --service-principal -u $env:AZURE_CLIENT_ID -p $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error en az login"
        exit 1
    }

    if ($Deploy -eq "all" -or $Deploy -eq "bootstrap") {
        # --- Bootstrap phase ---
        Write-Host "`n=== BOOTSTRAP: terraform init ==="
        Set-Location $bootstrapDir
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Bootstrap: terraform init failed."
            exit 1
        }

        Write-Host "`n=== BOOTSTRAP: terraform plan ==="
        terraform plan -var="subscription_id=$subscriptionId" -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Bootstrap: terraform plan failed."
            exit 1
        }

        Write-Host "`n=== BOOTSTRAP: terraform apply ==="
        terraform apply -var="subscription_id=$subscriptionId" -auto-approve tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Bootstrap: terraform apply failed."
            exit 1
        }
    }

    if ($Deploy -eq "all" -or $Deploy -eq "dev") {
        # --- Dev environment phase ---
        Write-Host "`n=== DEV ENV: terraform init with backend config ==="
        Set-Location $devEnvDir
        terraform init -backend-config="$backendConfig"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Dev Env: terraform init failed."
            exit 1
        }

        Write-Host "`n=== DEV ENV: terraform plan ==="
        terraform plan -var="subscription_id=$subscriptionId" -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Dev Env: terraform plan failed."
            exit 1
        }

        Write-Host "`n=== DEV ENV: terraform apply ==="
        terraform apply -var="subscription_id=$subscriptionId" -auto-approve tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Dev Env: terraform apply failed."
            exit 1
        }
    }

    Write-Host "`nSelected Terraform steps completed successfully."
    exit 0
}
finally {
    Set-Location $OriginalLocation
}
