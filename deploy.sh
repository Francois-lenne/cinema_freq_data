#!/bin/bash

# Configuration
PROJECT_ROOT=$(pwd)
SRC_DIR="$PROJECT_ROOT/src"
DEPLOYMENT_DIR="$PROJECT_ROOT/deployment_package"

echo "Starting Lambda packaging process..."

# Clean up any existing deployment directory
if [ -d "$DEPLOYMENT_DIR" ]; then
    echo "Cleaning up existing deployment directory..."
    rm -rf "$DEPLOYMENT_DIR"
fi

# Create deployment directory
echo "Creating deployment directory..."
mkdir -p "$DEPLOYMENT_DIR"

# Copy source code
echo "Copying source code..."
cp "$SRC_DIR/main.py" "$DEPLOYMENT_DIR/lambda_function.py"

# Create and activate virtual environment
echo "Setting up virtual environment..."
python3 -m venv "$DEPLOYMENT_DIR/venv"
source "$DEPLOYMENT_DIR/venv/bin/activate"

# Copy requirements.txt if it exists at project root
if [ -f "$PROJECT_ROOT/requirements.txt" ]; then
    cp "$PROJECT_ROOT/requirements.txt" "$DEPLOYMENT_DIR/"
    echo "Installing dependencies..."
    pip install -r "$DEPLOYMENT_DIR/requirements.txt" -t "$DEPLOYMENT_DIR/"
else
    echo "No requirements.txt found at project root!"
    exit 1
fi

# Deactivate virtual environment
echo "Deactivating virtual environment..."
deactivate

# Remove virtual environment and unnecessary files
echo "Cleaning up temporary files..."
rm -rf "$DEPLOYMENT_DIR/venv"
find "$DEPLOYMENT_DIR" -type d -name "__pycache__" -exec rm -rf {} +
find "$DEPLOYMENT_DIR" -type d -name "*.dist-info" -exec rm -rf {} +
find "$DEPLOYMENT_DIR" -type d -name "*.egg-info" -exec rm -rf {} +

# Create ZIP file
echo "Creating deployment package..."
cd "$DEPLOYMENT_DIR"
zip -r "$PROJECT_ROOT/lambda_deployment.zip" .
cd "$PROJECT_ROOT"

# Clean up deployment directory
rm -rf "$DEPLOYMENT_DIR"


echo "Lambda packaging process completed. Please finish the process"