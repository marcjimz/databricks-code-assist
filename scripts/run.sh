#!/bin/bash

# 🚀 Continue.dev + Databricks LLM Setup Script
# This script automates the setup process described in the README

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if correct number of arguments provided
if [ $# -ne 2 ]; then
    print_error "Usage: $0 <WORKSPACE_HOST> <WORKSPACE_API_TOKEN>"
    print_error "Example: $0 https://your-workspace.cloud.databricks.com dapi-your-token"
    exit 1
fi

WORKSPACE_HOST="$1"
WORKSPACE_API_TOKEN="$2"

# Remove trailing slash from workspace host if present
WORKSPACE_HOST="${WORKSPACE_HOST%/}"

print_status "Starting Continue.dev + Databricks LLM setup..."
print_status "Workspace Host: $WORKSPACE_HOST"
print_status "API Token: ${WORKSPACE_API_TOKEN:0:10}..."

# Change to the project directory
cd "$(dirname "$0")/.."

# Step 1: Verify Databricks connection
print_status "Step 1: Verifying Databricks connection..."
response=$(curl -s -w "%{http_code}" -X GET "https://$WORKSPACE_HOST/api/2.0/serving-endpoints" \
  -H "Authorization: Bearer $WORKSPACE_API_TOKEN" \
  -o /tmp/databricks_test.json)

if [ "$response" != "200" ]; then
    print_error "Failed to connect to Databricks workspace. HTTP status: $response"
    print_error "Please check your WORKSPACE_HOST and WORKSPACE_API_TOKEN"
    exit 1
fi

print_success "Successfully connected to Databricks workspace"

# Step 2: Install LiteLLM if not already installed
print_status "Step 2: Checking LiteLLM installation..."
if ! command -v litellm &> /dev/null; then
    print_status "Installing LiteLLM..."
    pip install 'litellm[proxy]' --upgrade
    print_success "LiteLLM installed successfully"
else
    print_success "LiteLLM is already installed"
fi

# Step 3: Create LiteLLM config from template
print_status "Step 3: Creating LiteLLM configuration..."
if [ ! -f "config/litellm_config.template.yaml" ]; then
    print_error "Template file config/litellm_config.template.yaml not found"
    exit 1
fi

sed -e "s|\${WORKSPACE_HOST}|$WORKSPACE_HOST|g" \
    -e "s|\${WORKSPACE_API_TOKEN}|$WORKSPACE_API_TOKEN|g" \
    config/litellm_config.template.yaml > litellm_config.yaml

print_success "LiteLLM configuration created"

# Step 4: Create logs directory if it doesn't exist
mkdir -p logs

# Step 5: Start LiteLLM proxy in background
print_status "Step 4: Starting LiteLLM proxy..."
# Kill any existing LiteLLM processes on port 4000
if lsof -ti:4000 >/dev/null 2>&1; then
    print_warning "Port 4000 is already in use. Stopping existing process..."
    kill $(lsof -ti:4000) 2>/dev/null || true
    sleep 2
fi

DATETIME=$(date '+%Y%m%d_%H%M%S')
nohup litellm --config litellm_config.yaml --port 4000 > logs/litellm_${DATETIME}.log 2>&1 &
LITELLM_PID=$!

print_success "LiteLLM proxy started with PID: $LITELLM_PID"
print_status "Logs are being written to: logs/litellm_${DATETIME}.log"

# Step 6: Wait for LiteLLM to start up
print_status "Step 5: Waiting for LiteLLM proxy to start up..."
sleep 5

# Test LiteLLM connection
for i in {1..10}; do
    if curl -s -f "http://localhost:4000/health" >/dev/null 2>&1; then
        print_success "LiteLLM proxy is running and healthy"
        break
    fi
    if [ $i -eq 10 ]; then
        print_error "LiteLLM proxy failed to start properly"
        print_error "Check the logs at: logs/litellm_${DATETIME}.log"
        exit 1
    fi
    print_status "Waiting for LiteLLM to be ready... (attempt $i/10)"
    sleep 2
done

# Step 7: Test LiteLLM with a simple request
print_status "Step 6: Testing LiteLLM proxy..."
test_response=$(curl -s -X POST "http://localhost:4000/v1/chat/completions" \
   -H "Content-Type: application/json" \
   -d '{
     "model": "claude-sonnet-4",
     "messages": [
       {"role": "user", "content": "Hello, respond with just OK"}
     ],
     "max_tokens": 10
   }' 2>/dev/null || echo "FAILED")

if [[ "$test_response" == *"OK"* ]] || [[ "$test_response" == *"content"* ]]; then
    print_success "LiteLLM proxy test successful"
else
    print_warning "LiteLLM proxy test may have failed, but continuing..."
    print_warning "You can check the logs at: logs/litellm_${DATETIME}.log"
fi

# Step 8: Create Continue.dev config
print_status "Step 7: Creating Continue.dev configuration..."
if [ ! -f "config/continue-config.template.yaml" ]; then
    print_error "Template file config/continue-config.template.yaml not found"
    exit 1
fi

# Create ~/.continue directory if it doesn't exist
mkdir -p ~/.continue

sed -e "s|\${WORKSPACE_HOST}|$WORKSPACE_HOST|g" \
    -e "s|\${WORKSPACE_API_TOKEN}|$WORKSPACE_API_TOKEN|g" \
    config/continue-config.template.yaml > ~/.continue/config.yaml

print_success "Continue.dev configuration created at ~/.continue/config.yaml"

# Final instructions
echo ""
print_success "🎉 Setup completed successfully!"
echo ""
print_status "Next steps:"
echo "  1. Open VS Code and install the Continue extension if not already installed"
echo "  2. Press CMD/CTRL + I to open the Continue panel"
echo "  3. Navigate to scripts/continue_tutorial.py to test the integration"
echo "  4. Select your model in the Continue.dev sidebar"
echo ""
print_status "LiteLLM proxy is running in the background (PID: $LITELLM_PID)"
print_status "Logs: logs/litellm_${DATETIME}.log"
echo ""
print_warning "Keep this terminal session alive or the LiteLLM proxy will stop!"
print_status "To stop the proxy later, run: kill $LITELLM_PID"
echo ""
print_status "To check if the proxy is still running:"
echo "  curl http://localhost:4000/health"
echo ""
print_success "Happy coding with Continue.dev + Databricks! 🚀"