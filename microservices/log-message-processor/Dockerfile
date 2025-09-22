# Use an official Python runtime as a parent image
FROM python:3.6-alpine

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . .

# Install any needed packages specified in requirements.txt
RUN apk add build-base

# Install dependencies
RUN pip install -r requirements.txt

# Environment variables
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379
ENV REDIS_CHANNEL=log_channel
ENV ZIPKIN_URL=http://zipkin:9411/api/v2/spans

# Execute the application
CMD ["python3","-u","main.py"]