# Build stage
FROM node:10-alpine AS builder

WORKDIR /app

# Install build dependencies for node-sass and other native modules
RUN apk add --no-cache \
    python2 \
    python2-dev \
    make \
    g++ \
    libc6-compat \
    git

# Copy package files first for better layer caching
COPY package*.json ./

# Configure npm
RUN npm config set python python2 && \
    npm config set unsafe-perm true

# Install dependencies with specific flags for node-sass compatibility
RUN npm install --verbose --no-optional

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration (optional - create if needed)
# COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Set default environment variables
ENV PORT=80
ENV AUTH_API_ADDRESS=http://127.0.0.1:8081
ENV TODOS_API_ADDRESS=http://127.0.0.1:8082
ENV ZIPKIN_URL=http://127.0.0.1:9411/api/v2/spans

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
