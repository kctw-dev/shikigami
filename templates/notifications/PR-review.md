<!-- Notification Template: PR Ready for Review -->
<!-- Placeholder format: {{VARIABLE_NAME}} — replace manually or via sed/envsubst -->

## PR Ready for Review

**Repository**: {{REPO_NAME}}
**PR**: #{{PR_NUMBER}} — {{PR_TITLE}}
**Author**: {{AUTHOR}}
**Branch**: `{{SOURCE_BRANCH}}` -> `{{TARGET_BRANCH}}`

### Summary

{{PR_DESCRIPTION}}

### Review Requested

- **Reviewer(s)**: {{REVIEWERS}}
- **Size**: {{PR_SIZE}} ({{FILES_CHANGED}} files, +{{ADDITIONS}}/-{{DELETIONS}})
- **Labels**: {{LABELS}}

### Action Required

Please review this PR at your earliest convenience.

**Link**: {{PR_URL}}

---

### Usage

Replace placeholders with actual values:

```bash
sed -e 's/{{REPO_NAME}}/my-project/g' \
    -e 's/{{PR_NUMBER}}/42/g' \
    -e 's/{{PR_TITLE}}/Add user authentication/g' \
    -e 's/{{AUTHOR}}/@developer/g' \
    templates/notifications/PR-review.md
```
