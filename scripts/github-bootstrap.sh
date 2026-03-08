#!/usr/bin/env bash
set -euo pipefail

REPO="DN-Codex-Pulse360/pulse360"

# Requires: gh auth login and admin rights on repository.

echo "Checking repo access..."
gh repo view "$REPO" --json name,url,defaultBranchRef

echo "Applying branch protection baseline to main..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/branches/main/protection" \
  -f required_status_checks.strict=true \
  -f enforce_admins=true \
  -f required_pull_request_reviews.required_approving_review_count=1 \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false || true

echo "Done. Review settings in GitHub UI."
