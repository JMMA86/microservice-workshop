# Crear imágenes Docker para los microservicios
Write-Host "Creating Docker Images for Microservices..."

# Variables para el ACR
$acrName = "msworkshop1devacr"
$acrLoginServer = "$acrName.azurecr.io"

# Login en Azure Container Registry
Write-Host "Logging in to Azure Container Registry..."
az acr login --name $acrName
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error logging in to ACR."
    exit 1
}

# Crear y etiquetar imágenes
$images = @(
    @{ name = "auth-api"; path = "./microservices/auth-api" },
    @{ name = "frontend"; path = "./microservices/frontend" },
    @{ name = "log-message-processor"; path = "./microservices/log-message-processor" },
    @{ name = "todos-api"; path = "./microservices/todos-api" },
    @{ name = "users-api"; path = "./microservices/users-api" },
    @{ name = "redis"; path = ""; baseImage = "redis:alpine" },
    @{ name = "zipkin"; path = ""; baseImage = "openzipkin/zipkin" }
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
        Write-Host "Error building/tagging/pushing $($img.name): $_"
        exit 1
    }
}

Write-Host "Docker Images built and pushed to ACR successfully."

# Limpieza de contenedores y red existentes
Write-Host "Cleaning up existing containers and network..."
docker rm -f auth-api frontend log-message-processor todos-api users-api redis zipkin 2>$null
docker network rm microservices-network 2>$null

# Crear red Docker
Write-Host "Creating Docker network..."
docker network create microservices-network

# Iniciar contenedor Redis
Write-Host "Starting Redis container..."
try {
    docker run -d --name redis --network microservices-network -p 6379:6379 $acrLoginServer/redis:latest
}
catch {
    Write-Host "Error creating Redis container: $_"
    exit 1
}

# Crear contenedores de microservicios usando imágenes de ACR
Write-Host "Creating Docker Containers for Microservices..."

try {
    docker run -d --name users-api --network microservices-network -p 8083:8080 `
        $acrLoginServer/users-api:latest
}
catch {
    Write-Host "Error creating users-api Docker container: $_"
    exit 1
}

Write-Host "Waiting for users-api to be ready..."
Start-Sleep -Seconds 15

try {
    docker run -d --name auth-api --network microservices-network -p 8081:8000 `
        $acrLoginServer/auth-api:latest
}
catch {
    Write-Host "Error creating auth-api Docker container: $_"
    exit 1
}

try {
    docker run -d --name todos-api --network microservices-network -p 8082:8082 `
        $acrLoginServer/todos-api:latest
}
catch {
    Write-Host "Error creating todos-api Docker container: $_"
    exit 1
}

try {
    docker run -d --name log-message-processor --network microservices-network `
        $acrLoginServer/log-message-processor:latest
}
catch {
    Write-Host "Error creating log-message-processor Docker container: $_"
    exit 1
}

docker run -d --name zipkin --network microservices-network -p 9411:9411 $acrLoginServer/zipkin:latest

try {
    docker run -d --name frontend --network microservices-network -p 8080:80 `
        $acrLoginServer/frontend:latest
}
catch {
    Write-Host "Error creating frontend Docker container: $_"
    exit 1
}

Write-Host "Docker Containers for Microservices created successfully."

Write-Host "`nRunning containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`nServices available at:"
Write-Host "Frontend: http://localhost:8080"
Write-Host "Auth API: http://localhost:8081"
Write-Host "Todos API: http://localhost:8082"
Write-Host "Users API: http://localhost:8083"
Write-Host "Redis: localhost:6379"