#!/bin/bash
# generate-review-package.sh
# Generates a review package from a git commit range for Phase 5 automated review loop
#
# Usage: ./generate-review-package.sh <feature-name> <commit-hash-or-range> <output-file>
#
# Example: ./generate-review-package.sh "filter-buttons-fix" 0c95147 review-package.md

set -euo pipefail

FEATURE_NAME="${1:?Usage: $0 <feature-name> <commit> <output-file>}"
COMMIT="${2:?Usage: $0 <feature-name> <commit> <output-file>}"
OUTPUT="${3:?Usage: $0 <feature-name> <commit> <output-file>}"

REVIEWS_DIR="$(dirname "$OUTPUT")"
mkdir -p "$REVIEWS_DIR"

REVIEW_ID="REV-$(date +%Y-%m-%d)-$(echo "$FEATURE_NAME" | md5sum | cut -c1-6)"
DATE=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

echo "Generating review package for: $FEATURE_NAME"
echo "Commit: $COMMIT"
echo "Review ID: $REVIEW_ID"

# Get git log for the commit
GIT_LOG=$(git log --oneline "$COMMIT" -1 2>/dev/null || git log --oneline "${COMMIT}..HEAD" -1 2>/dev/null)
GIT_DIFF=$(git show "$COMMIT" --stat 2>/dev/null || git diff "${COMMIT}~1..${COMMIT}" --stat 2>/dev/null)
GIT_FILES=$(git diff-tree --no-commit-id -r "$COMMIT" --name-only 2>/dev/null || git show "$COMMIT" --name-only --format="" 2>/dev/null)

cat > "$OUTPUT" <<TEMPLATE
---
review_id: $REVIEW_ID
project: Mission Control Dashboard
feature: $FEATURE_NAME
commit: $COMMIT
created: $DATE
priority: P1
status: pending
---

# Summary

Automated review for feature: **$FEATURE_NAME**

## Git History
$GIT_LOG

## Files Changed
$GIT_FILES

## Diff Summary
\`\`\`
$GIT_DIFF
\`\`\`

# Review Requests

1. **Code Quality**: Are there any code quality issues in the changed files?
2. **Architecture**: Does the implementation follow the project's architectural patterns?
3. **Performance**: Are there any performance concerns?
4. **Security**: Are there any security considerations?
5. **Maintainability**: Is the code maintainable and well-documented?
6. **Testing**: Should this change have associated tests?

## Output Format

Respond in valid JSON only (no markdown wrapping outside the JSON):

{
  "overall_quality": "excellent|good|adequate|needs_work",
  "architecture_score": "1-10",
  "code_quality_score": "1-10",
  "recommendations": [
    {
      "category": "code_quality|architecture|performance|security|maintainability|testing",
      "recommendation": "specific actionable recommendation",
      "priority": "critical|high|medium|low",
      "actionable": true
    }
  ],
  "additional_risks": [
    {
      "risk": "description",
      "likelihood": "low|medium|high",
      "impact": "low|medium|high"
    }
  ],
  "verdict": "one paragraph summary"
}
TEMPLATE

echo "Review package saved to: $OUTPUT"
echo "Submit with: opencode run --model openrouter/qwen/qwen3-coder --print-logs \"\$(cat $OUTPUT)\""
