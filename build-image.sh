#!/bin/bash
IMAGE_NAME="joelrobinson791/capstone-app"

read -p "Enter the tag for the docker image, default is 'v1': " TAG
TAG=${TAG:-v1}

echo "Building Docker image: $IMAGE_NAME:$TAG"
docker build -t "$IMAGE_NAME:$TAG" .