# Creating Docker Images for Microservices
Write-Host "Creating Docker Images for Microservices..."

# Create auth-api Docker Image
try {
    docker build -t auth-api:latest -f ./microservices/auth-api/Dockerfile ./microservices/auth-api
}
catch {
    Write-Host "Error creating auth-api Docker image: $_"
    exit 1
}

# Create frontend Docker Image
try {
    docker build -t frontend:latest -f ./microservices/frontend/Dockerfile ./microservices/frontend
}
catch {
    Write-Host "Error creating frontend Docker image: $_"
    exit 1
}

# Create log-message-processor Docker Image
try {
    docker build -t log-message-processor:latest -f ./microservices/log-message-processor/Dockerfile ./microservices/log-message-processor
}
catch {
    Write-Host "Error creating log-message-processor Docker image: $_"
    exit 1
}

# Create todos-api Docker Image
try {
    docker build -t todos-api:latest -f ./microservices/todos-api/Dockerfile ./microservices/todos-api
}
catch {
    Write-Host "Error creating todos-api Docker image: $_"
    exit 1
}

# Create users-api Docker Image
try {
    docker build -t users-api:latest -f ./microservices/users-api/Dockerfile ./microservices/users-api
}
catch {
    Write-Host "Error creating users-api Docker image: $_"
    exit 1
}

Write-Host "Docker Images for Microservices created successfully."

# Clean up existing containers and network
Write-Host "Cleaning up existing containers and network..."
docker rm -f auth-api frontend log-message-processor todos-api users-api redis zipkin 2>$null
docker network rm microservices-network 2>$null

# Create Docker network
Write-Host "Creating Docker network..."
docker network create microservices-network

# Start Redis container (required by log-message-processor)
Write-Host "Starting Redis container..."
try {
    docker run -d --name redis --network microservices-network -p 6379:6379 redis:alpine
}
catch {
    Write-Host "Error creating Redis container: $_"
    exit 1
}

# Creating Docker Containers for Microservices
Write-Host "Creating Docker Containers for Microservices..."

# Create users-api Docker Container (first, as other services depend on it)
try {
    docker run -d --name users-api --network microservices-network -p 8083:8080 `
        -e JWT_SECRET=myfancysecret `
        -e SERVER_PORT=8080 `
        users-api:latest
}
catch {
    Write-Host "Error creating users-api Docker container: $_"
    exit 1
}

# Wait for users-api to be ready
Write-Host "Waiting for users-api to be ready..."
Start-Sleep -Seconds 15

# Create auth-api Docker Container (fixed port mapping)
try {
    docker run -d --name auth-api --network microservices-network -p 8081:8000 `
        -e AUTH_API_PORT=8000 `
        -e USERS_API_ADDRESS=http://users-api:8080 `
        -e JWT_SECRET=myfancysecret `
        auth-api:latest
}
catch {
    Write-Host "Error creating auth-api Docker container: $_"
    exit 1
}

# Create todos-api Docker Container
try {
    docker run -d --name todos-api --network microservices-network -p 8082:8082 `
        -e TODO_API_PORT=8082 `
        -e JWT_SECRET=myfancysecret `
        -e USERS_API_ADDRESS=http://users-api:8080 `
        -e REDIS_HOST=redis `
        -e REDIS_PORT=6379 `
        -e REDIS_CHANNEL=log_channel `
        -e ZIPKIN_URL=http://zipkin:9411/api/v2/spans `
        todos-api:latest
}
catch {
    Write-Host "Error creating todos-api Docker container: $_"
    exit 1
}

# Create log-message-processor Docker Container (with Redis connection)
try {
    docker run -d --name log-message-processor --network microservices-network `
        -e REDIS_HOST=redis `
        -e REDIS_PORT=6379 `
        -e REDIS_CHANNEL=log_channel `
        -e ZIPKIN_URL=http://zipkin:9411/api/v2/spans `
        log-message-processor:latest
}
catch {
    Write-Host "Error creating log-message-processor Docker container: $_"
    exit 1
}

# Agregar antes del frontend en el script
docker run -d --name zipkin --network microservices-network -p 9411:9411 openzipkin/zipkin

# Create frontend Docker Container (fixed environment variables for container network)
try {
    docker run -d --name frontend --network microservices-network -p 8080:80 `
        frontend:latest
}
catch {
    Write-Host "Error creating frontend Docker container: $_"
    exit 1
}

Write-Host "Docker Containers for Microservices created successfully."

# Display running containers
Write-Host "`nRunning containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`nServices available at:"
Write-Host "Frontend: http://localhost:8080"
Write-Host "Auth API: http://localhost:8081"
Write-Host "Todos API: http://localhost:8082"
Write-Host "Users API: http://localhost:8083"
Write-Host "Redis: localhost:6379"