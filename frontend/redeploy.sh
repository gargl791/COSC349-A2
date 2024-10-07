#!/bin/bash

# Build the Docker image
docker build -t ec2-frontend:v1.0 -f Dockerfile .

# Run the Docker container
docker run -d -p 80:5173 ec2-frontend:v1.0

echo "Docker container running on port 80"
