#!/bin/bash
echo "deploy image to server"
read -p "enter the image name to deploy (default is 'joelrobinson791/capstone-app:v1'): " IMAGE_NAME
IMAGE_NAME=${IMAGE_NAME:-joelrobinson791/capstone-app:v1}
echo "Deploying Docker image: $IMAGE_NAME"
# Pull the Docker image from Docker Hub
docker pull "$IMAGE_NAME"
# run the Docker container with the specified image
docker run -d -p 80:80 "$IMAGE_NAME"