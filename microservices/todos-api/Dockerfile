# Usar imagen base oficial de Node.js
FROM node:18-alpine

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el código de la aplicación
COPY . .

# Set default environment variables
ARG TODO_API_PORT
ARG JWT_SECRET
ARG REDIS_HOST
ARG REDIS_ZHK_PORT
ARG REDIS_CHANNEL
ARG ZIPKIN_URL
ENV TODO_API_PORT=$TODO_API_PORT
ENV JWT_SECRET=$JWT_SECRET
ENV REDIS_HOST=$REDIS_HOST
ENV REDIS_ZHK_PORT=$REDIS_ZHK_PORT
ENV REDIS_CHANNEL=$REDIS_CHANNEL
ENV ZIPKIN_URL=$ZIPKIN_URL

# Exponer el puerto
EXPOSE 8082

# Comando para ejecutar la aplicación
CMD ["npm", "start"]