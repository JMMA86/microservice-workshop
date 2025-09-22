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
EXPOSE 8000

# Set default environment variables
ENV AUTH_API_PORT=8000
ENV USERS_API_ADDRESS=http://users-api:8080
ENV JWT_SECRET=myfancysecret

# Run the binary
CMD ["./main"]
