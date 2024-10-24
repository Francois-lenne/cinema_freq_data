# Configuration
$PROJECT_ROOT = (Get-Location).Path
$SRC_DIR = "$PROJECT_ROOT\src"
$DEPLOYMENT_DIR = "$PROJECT_ROOT\deployment_package"



Write-Host "Starting Lambda packaging process... "

# Clean up any existing deployment directory
if (Test-Path $DEPLOYMENT_DIR) {
    Write-Host "Cleaning up existing deployment directory..."
    Remove-Item -Recurse -Force $DEPLOYMENT_DIR
}


# Create deployment directory

Write-Host "Creating deployment directory..."

New-Item -ItemType Directory -Force -Path $DEPLOYMENT_DIR


# Copy source code
Write-Host "Copying source code..."
Copy-Item "$SRC_DIR\main.py" "$DEPLOYMENT_DIR\lambda_function.py"


# Create and activate virtual environment
Write-Host "Setting up virtual environment..."
python -m venv "$DEPLOYMENT_DIR\venv"
& "$DEPLOYMENT_DIR\venv\Scripts\Activate.ps1"



# Copy requirements.txt if it exists at project root
if (Test-Path "$PROJECT_ROOT\requirements.txt") {
    Copy-Item "$PROJECT_ROOT\requirements.txt" "$DEPLOYMENT_DIR\"
    Write-Host "Installing dependencies..."
    pip install -r "$DEPLOYMENT_DIR\requirements.txt" -t "$DEPLOYMENT_DIR\"
} else {
    Write-Host "No requirements.txt found at project root!"
    exit 1
}


# Deactivate virtual environment

Write-Host "Deactivating virtual environment..."
deactivate


# Remove virtual environment and unnecessary files
Write-Host "Cleaning up temporary files..."
Remove-Item -Recurse -Force "$DEPLOYMENT_DIR\venv"
Get-ChildItem -Recurse -Directory "$DEPLOYMENT_DIR" -Include "__pycache__", "*.dist-info", "*.egg-info" | Remove-Item -Recurse -Force


# Create ZIP file
Write-Host "Creating deployment package..."
Set-Location -Path $DEPLOYMENT_DIR
Compress-Archive -Path . -DestinationPath "$PROJECT_ROOT\lambda_deployment.zip"
Set-Location -Path $PROJECT_ROOT


# Clean up deployment directory
Remove-Item -Recurse -Force $DEPLOYMENT_DIR