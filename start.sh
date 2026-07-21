#!/bin/bash
# Panopticon — startup script
# Generates .env + cliproxy-config.yaml from secrets system, starts Docker stack
# Stack: LiteLLM proxy + CLIProxyAPI + PostgreSQL + Langfuse + Redis

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

mkdir -p cliproxy-auths cliproxy-logs

# Verify required secrets exist
MISSING=0
for KEY in MODELOS_AI_KEY LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY ALIBABA_TOKEN_PLAN_KEY ZEN_API_KEY; do
    if ! zsh -lic "secrets has $KEY" 2>/dev/null; then
        echo "ERROR: $KEY not found in secrets."
        MISSING=1
    fi
done
if [ $MISSING -eq 1 ]; then
    echo ""
    echo "Add missing keys with:"
    echo "  secrets prompt MODELOS_AI_KEY"
    echo "  secrets prompt LANGFUSE_PUBLIC_KEY"
    echo "  secrets prompt LANGFUSE_SECRET_KEY"
    echo "  secrets prompt ALIBABA_TOKEN_PLAN_KEY"
    echo "  secrets prompt ZEN_API_KEY"
    exit 1
fi

# Generate .env from secrets (keys never appear in shell history)
zsh -lic '
echo "MODELOS_AI_KEY_API_KEY=$MODELOS_AI_KEY_API_KEY"
echo "LANGFUSE_PUBLIC_KEY_API_KEY=$LANGFUSE_PUBLIC_KEY_API_KEY"
echo "LANGFUSE_SECRET_KEY_API_KEY=$LANGFUSE_SECRET_KEY_API_KEY"
echo "ALIBABA_TOKEN_PLAN_KEY_API_KEY=$ALIBABA_TOKEN_PLAN_KEY_API_KEY"
echo "ZEN_API_KEY_API_KEY=$ZEN_API_KEY_API_KEY"
echo "MISTRAL_API_KEY_API_KEY=${MISTRAL_API_KEY_API_KEY:-}"
' > .env
chmod 600 .env

zsh -lic '
sed "s|__ALIBABA_KEY__|$ALIBABA_TOKEN_PLAN_KEY_API_KEY|g" cliproxy-config.tmpl.yaml
' > cliproxy-config.yaml
chmod 600 cliproxy-config.yaml

# Start the stack
docker compose up -d

echo ""
echo "Stack running:"
echo "  LiteLLM proxy:    http://localhost:4000"
echo "  Langfuse UI:      http://localhost:3000  (admin@local.dev / admin1234)"
echo "  CLIProxyAPI:      http://127.0.0.1:8317/management.html  (cliproxy-mgmt-local)"
echo "  Stop:             docker compose down"
echo "  Logs:             docker compose logs -f"
