#!/bin/bash

# Build the Docker image
docker build -t ec2-backend:v1.0 -f Dockerfile .

# Run the Docker container
docker run -d -p 81:3000 ec2-backend:v1.0

echo "Docker container running on port 81"
