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

# Define build arguments
ARG AZURE_IP=PLACEHOLDER_AZURE_IP
ARG FRONTEND_PORT=80
ARG AUTH_API_PORT=8081
ARG TODOS_API_PORT=8082
ARG ZIPKIN_URL=http://zipkin:9411/api/v2/spans

# Convert ARGs to ENV variables for Vue.js build process
ENV PORT=${FRONTEND_PORT}
ENV VUE_APP_AUTH_API_ADDRESS=http://${AZURE_IP}:${AUTH_API_PORT}
ENV VUE_APP_TODOS_API_ADDRESS=http://${AZURE_IP}:${TODOS_API_PORT}
ENV VUE_APP_ZIPKIN_URL=${ZIPKIN_URL}

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built assets from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy the configuration generation script
COPY generate-config.sh /usr/local/bin/generate-config.sh
RUN chmod +x /usr/local/bin/generate-config.sh

# Copy nginx configuration (optional - create if needed)
# COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start with configuration generation
CMD ["/usr/local/bin/generate-config.sh"]
