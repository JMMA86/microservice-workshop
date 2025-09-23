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
ENV TODO_API_PORT=8082
ENV JWT_SECRET=myfancysecret
ENV REDIS_HOST=redis
ENV REDIS_ZHK_PORT=6379
ENV REDIS_CHANNEL=log_channel
ENV ZIPKIN_URL=http://zipkin:9411/api/v2/spans

# Exponer el puerto
EXPOSE 8082

# Comando para ejecutar la aplicación
CMD ["npm", "start"]