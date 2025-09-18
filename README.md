# 🚀 Continue.dev + Databricks LLM Setup Guide

## Prerequisites

### System Requirements
- 💻 VS Code or JetBrains IDE
- 🌐 Internet connection
- 🔧 Databricks workspace with Foundation Model APIs access

## Continue.dev Installation

### Install Extension
```bash
code --install-extension Continue.continue
```

**Config Location:** `~/.continue/` (macOS/Linux) or `%USERPROFILE%\.continue\` (Windows)

## Databricks Setup

### 🔑 Generate Access Token

```
Workspace Settings → Advanced → Personal Access Tokens → Generate New Token
```

### Store Credentials

```bash
export WORKSPACE_HOST=<your-workspace-host>
export WORKSPACE_API_TOKEN=dapi-<your-token>
```

### ✅ Verify Connection

**List endpoints:**
```bash
curl -X GET "https://$WORKSPACE_HOST/api/2.0/serving-endpoints" \
  -H "Authorization: Bearer $WORKSPACE_API_TOKEN"
```

**Test Claude:**
```bash
curl -X POST "https://$WORKSPACE_HOST/serving-endpoints/databricks-claude-sonnet-4/invocations" \
  -H "Authorization: Bearer $WORKSPACE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

## 3️⃣ LiteLLM Proxy Setup

This is needed to support the OpenAI compliant nature of Continue.DEV code assistant. This utility will need to run while VSCode is open.

### 🔧 Install & Configure
```bash
# Install LiteLLM
pip install 'litellm[proxy]' --upgrade

# Create config from template
sed -e "s/\${WORKSPACE_HOST}/$WORKSPACE_HOST/g" \
    -e "s/\${WORKSPACE_API_TOKEN}/$WORKSPACE_API_TOKEN/g" \
    config/litellm_config.template.yaml > litellm_config.yaml

# Start proxy
litellm --config litellm_config.yaml --port 4000
```

### 🧪 Test LiteLLM
Open new terminal:
```bash
curl -X POST "http://localhost:4000/v1/chat/completions" \
   -H "Content-Type: application/json" \
   -d '{
     "model": "claude-sonnet-4",
     "messages": [
       {"role": "user", "content": "Hello, can you hear me?"}
     ],
     "max_tokens": 100
   }'
```

## 4️⃣ Continue.dev Configuration

### 📝 Create Config
```bash
# Generate from template (make sure ENV vars are loaded)
sed -e "s/\${WORKSPACE_HOST}/$WORKSPACE_HOST/g" \
    -e "s/\${WORKSPACE_API_TOKEN}/$WORKSPACE_API_TOKEN/g" \
    config/continue-config.template.yaml > ~/.continue/config.yaml
```

### 🔄 Reload VS Code
`Cmd/Ctrl + Shift + P` → `Developer: Reload Window`

## 5️⃣ Final Testing

### 🎯 Test Your Setup
1. 📂 Navigate to `scripts/continue_tutorial.py`
2. 💬 Follow the comments to test Continue.dev + Databricks integration
3. 🎉 Select your model in Continue.dev sidebar

## ⚡ Quick Reference

### Required Config Parameters
```yaml
provider: openai              # Always "openai" for Databricks
model: claude-sonnet-4        # Exact model name
apiBase: http://localhost:4000/v1  # LiteLLM proxy URL
apiKey: dummy                 # Or your master key if configured
```

### Model Roles
```yaml
roles:
  - chat         # 💬 Conversations
  - edit         # ✏️ Code editing
  - apply        # ✔️ Apply changes
  - autocomplete # 🔮 Tab completion
```

💡 **Pro Tip:** Keep LiteLLM running in a separate terminal or use `nohup` for background operation!

🎉 **Happy Coding with Continue.dev + Databricks!**