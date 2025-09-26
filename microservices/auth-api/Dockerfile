# Build stage
FROM golang:1.19-alpine AS builder

WORKDIR /app

# Initialize go module
RUN go mod init auth-api

# Copy source code first
COPY . .

# Install dependencies based on imports in the code
RUN apk add --no-cache git && \
    go mod tidy && \
    go mod download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

# Add ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Set default environment variables
ENV AUTH_ZHK_API_PORT=${AUTH_API_PORT:-8080}
ENV USERS_API_ADDRESS=${USERS_API_URL:-http://users-api:8083}

# Run the binary
CMD ["./main"]
