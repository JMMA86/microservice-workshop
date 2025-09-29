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
ARG REDIS_HOST
ARG REDIS_ZHK_PORT
ARG REDIS_CHANNEL
ARG ZIPKIN_URL
ENV REDIS_HOST=$REDIS_HOST
ENV REDIS_ZHK_PORT=$REDIS_ZHK_PORT
ENV REDIS_CHANNEL=$REDIS_CHANNEL
ENV ZIPKIN_URL=$ZIPKIN_URL

# Execute the application
CMD ["python3","-u","main.py"]