#!/bin/sh

# Set default values if environment variables are not provided
AUTH_API_ADDRESS=${VUE_APP_AUTH_API_ADDRESS:-"http://localhost:8081"}
TODOS_API_ADDRESS=${VUE_APP_TODOS_API_ADDRESS:-"http://localhost:8082"}
ZIPKIN_URL=${VUE_APP_ZIPKIN_URL:-"http://localhost:9411/api/v2/spans"}

# Generate runtime configuration
cat <<EOF > /usr/share/nginx/html/config.js
window.APP_CONFIG = {
  AUTH_API_ADDRESS: "${AUTH_API_ADDRESS}",
  TODOS_API_ADDRESS: "${TODOS_API_ADDRESS}", 
  ZIPKIN_URL: "${ZIPKIN_URL}"
};
EOF

echo "Generated configuration:"
cat /usr/share/nginx/html/config.js

# Start nginx
nginx -g "daemon off;"