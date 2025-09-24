# Circuit Breaker Testing Script for PowerShell
# Automatiza las pruebas del circuit breaker en Kubernetes

param(
    [string]$TestType = "all",
    [int]$WaitTime = 30
)

Write-Host "Circuit Breaker Testing Script" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

function Test-ServiceHealth {
    Write-Host "`nVerificando estado de servicios..." -ForegroundColor Yellow
    
    $pods = kubectl get pods --no-headers
    Write-Host "Pods activos:"
    Write-Host $pods
    
    $services = kubectl get services --no-headers
    Write-Host "`nServicios:"
    Write-Host $services
    
    # Verificar que todos los pods estén Running
    $notReadyPods = kubectl get pods --no-headers | Where-Object { $_ -notmatch "Running" -or $_ -match "0/" }
    if ($notReadyPods) {
        Write-Host "ATENCION: Algunos pods no están Ready:" -ForegroundColor Yellow
        $notReadyPods | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    } else {
        Write-Host "OK: Todos los pods están Running y Ready" -ForegroundColor Green
    }
}

function Start-PortForwards {
    Write-Host "`nIniciando port-forwards..." -ForegroundColor Yellow
    
    Start-Job -ScriptBlock { kubectl port-forward svc/auth-api 8080:8080 } -Name "auth-port-forward" | Out-Null
    Start-Job -ScriptBlock { kubectl port-forward svc/users-api 8083:8083 } -Name "users-port-forward" | Out-Null
    Start-Job -ScriptBlock { kubectl port-forward svc/frontend 3000:80 } -Name "frontend-port-forward" | Out-Null
    
    Start-Sleep 5
    Write-Host "Port-forwards iniciados" -ForegroundColor Green
}

function Test-InitialState {
    Write-Host "`nTest 1: Estado inicial del circuit breaker" -ForegroundColor Magenta
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/circuit-breaker-status" -Method GET
        Write-Host "Estado del Circuit Breaker: $($response.state)" -ForegroundColor Green
        Write-Host "Fallas: $($response.failures)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR obteniendo estado del circuit breaker: $_" -ForegroundColor Red
        return $false
    }
}

function Test-SuccessfulLogin {
    Write-Host "`nTest 2: Login exitoso" -ForegroundColor Magenta
    
    $loginData = @{
        username = "admin"
        password = "admin"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/login" -Method POST -Body $loginData -ContentType "application/json"
        Write-Host "OK: Login exitoso - Token obtenido" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "ERROR en login: $_" -ForegroundColor Red
        return $false
    }
}

function Test-CircuitBreakerOpen {
    Write-Host "`nTest 3: Abriendo circuit breaker" -ForegroundColor Magenta
    
    # Escalar users-api a 0
    Write-Host "Escalando users-api a 0 replicas..." -ForegroundColor Yellow
    kubectl scale deployment users-api --replicas=0
    Start-Sleep 10
    
    $loginData = @{
        username = "admin"
        password = "admin"
    } | ConvertTo-Json
    
    # Hacer 3 intentos para abrir el circuit breaker
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "Intento $i de login..." -ForegroundColor Yellow
        
        try {
            Invoke-RestMethod -Uri "http://localhost:8080/auth-api/login" -Method POST -Body $loginData -ContentType "application/json" | Out-Null
        } catch {
            Write-Host "Falla esperada en intento $i" -ForegroundColor Yellow
        }
        
        # Verificar estado del circuit breaker
        try {
            $cbState = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/circuit-breaker-status" -Method GET
            Write-Host "  Estado CB: $($cbState.state), Fallas: $($cbState.failures)" -ForegroundColor Cyan
        } catch {
            Write-Host "  No se pudo obtener estado del CB" -ForegroundColor Red
        }
        
        Start-Sleep 2
    }
    
    # Verificar que el CB está abierto
    try {
        $finalState = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/circuit-breaker-status" -Method GET
        if ($finalState.state -eq "OPEN") {
            Write-Host "OK: Circuit Breaker está ABIERTO correctamente" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ERROR: Circuit Breaker debería estar ABIERTO pero está: $($finalState.state)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "ERROR verificando estado final del CB" -ForegroundColor Red
        return $false
    }
}

function Test-FastFail {
    Write-Host "`nTest 4: Verificando respuesta rápida con CB abierto" -ForegroundColor Magenta
    
    $loginData = @{
        username = "admin"
        password = "admin"
    } | ConvertTo-Json
    
    $startTime = Get-Date
    try {
        Invoke-RestMethod -Uri "http://localhost:8080/auth-api/login" -Method POST -Body $loginData -ContentType "application/json" | Out-Null
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        if ($duration -lt 1000) {
            Write-Host "OK: Respuesta rápida con CB abierto: ${duration}ms" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ERROR: Respuesta demasiado lenta: ${duration}ms" -ForegroundColor Red
            return $false
        }
    }
}

function Test-Recovery {
    Write-Host "`nTest 5: Recuperación del circuit breaker" -ForegroundColor Magenta
    
    # Restaurar users-api
    Write-Host "Restaurando users-api..." -ForegroundColor Yellow
    kubectl scale deployment users-api --replicas=1
    
    Write-Host "Esperando a que el pod esté listo..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l app=users-api --timeout=60s
    
    # Esperar el timeout del circuit breaker
    Write-Host "Esperando ${WaitTime}s para que el CB pase a HALF_OPEN..." -ForegroundColor Yellow
    Start-Sleep $WaitTime
    
    # Verificar estado HALF_OPEN
    try {
        $cbState = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/circuit-breaker-status" -Method GET
        Write-Host "Estado actual del CB: $($cbState.state)" -ForegroundColor Cyan
    } catch {
        Write-Host "No se pudo verificar estado del CB" -ForegroundColor Red
    }
    
    # Hacer login exitoso
    $loginData = @{
        username = "admin"
        password = "admin"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/login" -Method POST -Body $loginData -ContentType "application/json"
        Write-Host "OK: Login exitoso después de recuperación" -ForegroundColor Green
        
        # Verificar que el CB está cerrado
        $finalState = Invoke-RestMethod -Uri "http://localhost:8080/auth-api/circuit-breaker-status" -Method GET
        if ($finalState.state -eq "CLOSED") {
            Write-Host "OK: Circuit Breaker está CERRADO - Recuperación exitosa" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ERROR: CB debería estar CERRADO pero está: $($finalState.state)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "ERROR en login de recuperación: $_" -ForegroundColor Red
        return $false
    }
}

function Stop-PortForwards {
    Write-Host "`nDeteniendo port-forwards..." -ForegroundColor Yellow
    
    Get-Job | Where-Object { $_.Name -match "port-forward" } | Stop-Job
    Get-Job | Where-Object { $_.Name -match "port-forward" } | Remove-Job
    
    Write-Host "Port-forwards detenidos" -ForegroundColor Green
}

function Show-Results {
    param($results)
    
    Write-Host "`nRESULTADOS FINALES" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    
    $passed = 0
    $total = $results.Count
    
    foreach ($result in $results) {
        $status = if ($result.Success) { "PASSED" } else { "FAILED" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        Write-Host "$status - $($result.Name)" -ForegroundColor $color
        if ($result.Success) { $passed++ }
    }
    
    Write-Host "`nResumen: $passed/$total tests pasaron" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
}

# Script principal
try {
    $results = @()
    
    Test-ServiceHealth
    Start-PortForwards
    
    if ($TestType -eq "all" -or $TestType -eq "initial") {
        $results += @{ Name = "Estado inicial"; Success = Test-InitialState }
    }
    
    if ($TestType -eq "all" -or $TestType -eq "login") {
        $results += @{ Name = "Login exitoso"; Success = Test-SuccessfulLogin }
    }
    
    if ($TestType -eq "all" -or $TestType -eq "failure") {
        $results += @{ Name = "Circuit Breaker abierto"; Success = Test-CircuitBreakerOpen }
        $results += @{ Name = "Respuesta rápida"; Success = Test-FastFail }
    }
    
    if ($TestType -eq "all" -or $TestType -eq "recovery") {
        $results += @{ Name = "Recuperación"; Success = Test-Recovery }
    }
    
    Show-Results $results
    
} catch {
    Write-Host "ERROR ejecutando tests: $_" -ForegroundColor Red
} finally {
    Stop-PortForwards
}

Write-Host "`nTests completados. Servicios restaurados." -ForegroundColor Green