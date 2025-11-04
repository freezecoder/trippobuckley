#!/bin/bash

# Script to kill processes running on a given port

# Check if port number is provided
if [ -z "$1" ]; then
    echo "Usage: ./killport.sh <port_number>"
    echo "Example: ./killport.sh 8000"
    exit 1
fi

PORT=$1

# Find process IDs using the port
PIDS=$(lsof -ti:$PORT 2>/dev/null)

if [ -z "$PIDS" ]; then
    echo "No processes found running on port $PORT"
    exit 0
fi

echo "Found processes on port $PORT:"
lsof -i:$PORT

echo ""
echo "Killing processes..."
echo $PIDS | xargs kill -9

echo "Port $PORT has been freed"
