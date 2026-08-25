#!/usr/bin/env bash
set -euo pipefail

# Deploy West Coast Immigration landing to GitHub + Coolify
# Required env vars:
#   GITHUB_TOKEN      - GitHub PAT with repo scope
#   COOLIFY_URL       - e.g. https://coolify.probcapital.com
#   COOLIFY_TOKEN     - Coolify API bearer token
# Optional:
#   GITHUB_REPO       - repo name (default: west-coast-immigration-landing)
#   GITHUB_OWNER      - GitHub username/org (auto-detected if omitted)

REPO_NAME="${GITHUB_REPO:-west-coast-immigration-landing}"
BRANCH="${GIT_BRANCH:-main}"

echo "==> Authenticating with GitHub..."
echo "$GITHUB_TOKEN" | gh auth login --with-token
GITHUB_OWNER="${GITHUB_OWNER:-$(gh api user -q .login)}"
REMOTE_URL="https://github.com/${GITHUB_OWNER}/${REPO_NAME}.git"

echo "==> Ensuring branch is ${BRANCH}..."
git branch -M "${BRANCH}" 2>/dev/null || true

if gh repo view "${GITHUB_OWNER}/${REPO_NAME}" >/dev/null 2>&1; then
  echo "==> Repository exists, pushing updates..."
  git remote remove origin 2>/dev/null || true
  git remote add origin "${REMOTE_URL}"
  git push -u origin "${BRANCH}" --force
else
  echo "==> Creating GitHub repository ${GITHUB_OWNER}/${REPO_NAME}..."
  gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push --description "Premium immigration lawyer landing page for California"
fi

echo "==> GitHub repo ready: ${REMOTE_URL}"

COOLIFY_URL="${COOLIFY_URL%/}"
API="${COOLIFY_URL}/api/v1"
AUTH_HEADER="Authorization: Bearer ${COOLIFY_TOKEN}"

echo "==> Fetching Coolify resources..."
PROJECTS=$(curl -sf -H "${AUTH_HEADER}" "${API}/projects")
PROJECT_UUID=$(echo "$PROJECTS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['uuid'] if d else '')")

if [[ -z "$PROJECT_UUID" ]]; then
  echo "ERROR: No Coolify projects found. Create a project in Coolify first."
  exit 1
fi

SERVERS=$(curl -sf -H "${AUTH_HEADER}" "${API}/servers")
SERVER_UUID=$(echo "$SERVERS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['uuid'] if d else '')")

if [[ -z "$SERVER_UUID" ]]; then
  echo "ERROR: No Coolify servers found."
  exit 1
fi

ENVIRONMENTS=$(curl -sf -H "${AUTH_HEADER}" "${API}/projects/${PROJECT_UUID}/environments")
ENV_UUID=$(echo "$ENVIRONMENTS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['uuid'] if d else '')")
ENV_NAME=$(echo "$ENVIRONMENTS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['name'] if d else 'production')")

echo "==> Using project=${PROJECT_UUID}, server=${SERVER_UUID}, env=${ENV_NAME}"

# Check if app already exists
APPS=$(curl -sf -H "${AUTH_HEADER}" "${API}/applications" || echo "[]")
EXISTING_UUID=$(echo "$APPS" | python3 -c "
import sys, json
apps = json.load(sys.stdin)
repo = '${GITHUB_OWNER}/${REPO_NAME}'
for app in apps:
    if repo in str(app.get('git_repository', '')):
        print(app['uuid'])
        break
" 2>/dev/null || true)

if [[ -n "$EXISTING_UUID" ]]; then
  echo "==> Application exists (${EXISTING_UUID}), triggering deploy..."
  curl -sf -X POST -H "${AUTH_HEADER}" "${API}/applications/${EXISTING_UUID}/start"
  APP_UUID="$EXISTING_UUID"
else
  echo "==> Creating Coolify application..."
  PAYLOAD=$(python3 - <<PY
import json
print(json.dumps({
    "project_uuid": "${PROJECT_UUID}",
    "server_uuid": "${SERVER_UUID}",
    "environment_name": "${ENV_NAME}",
    "environment_uuid": "${ENV_UUID}",
    "git_repository": "${REMOTE_URL}",
    "git_branch": "${BRANCH}",
    "build_pack": "dockerfile",
    "name": "west-coast-immigration-landing",
    "ports_exposes": "80",
    "instant_deploy": True,
    "is_auto_deploy_enabled": True,
}))
PY
)
  RESPONSE=$(curl -sf -X POST -H "${AUTH_HEADER}" -H "Content-Type: application/json" \
    -d "$PAYLOAD" "${API}/applications/public")
  APP_UUID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('uuid',''))")
  echo "==> Created application: ${APP_UUID}"
fi

echo "==> Deployment triggered successfully!"
echo "    GitHub: https://github.com/${GITHUB_OWNER}/${REPO_NAME}"
echo "    Coolify app UUID: ${APP_UUID}"
