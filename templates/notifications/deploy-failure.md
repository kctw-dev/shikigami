<!-- Notification Template: Deployment Failure -->
<!-- Placeholder format: {{VARIABLE_NAME}} — replace manually or via sed/envsubst -->

## Deployment Failed

**Service**: {{SERVICE_NAME}}
**Version**: {{VERSION}}
**Environment**: {{DEPLOY_ENV}}
**Failed at**: {{FAILURE_TIMESTAMP}}

### Failure Details

- **Deployer**: {{DEPLOYER}}
- **Commit**: {{COMMIT_SHA}} (`{{COMMIT_MESSAGE}}`)
- **Stage**: {{FAILURE_STAGE}}
- **Error**: {{ERROR_MESSAGE}}

### Impact

- **Affected Services**: {{AFFECTED_SERVICES}}
- **User Impact**: {{USER_IMPACT}}
- **Error Budget Remaining**: {{ERROR_BUDGET}}

### Rollback Status

- **Rollback Initiated**: {{ROLLBACK_INITIATED}}
- **Rollback Target**: {{ROLLBACK_VERSION}}
- **Rollback Status**: {{ROLLBACK_STATUS}}

### Action Required

1. Investigate root cause: {{ERROR_MESSAGE}}
2. Check logs: {{LOG_URL}}
3. Verify rollback completion
4. File incident report if SLO breached

**Incident Channel**: {{INCIDENT_CHANNEL}}

---

### Usage

Replace placeholders with actual values:

```bash
sed -e 's/{{SERVICE_NAME}}/shikigami/g' \
    -e 's/{{VERSION}}/v0.20.0/g' \
    -e 's|{{ERROR_MESSAGE}}|Health check timeout after 30s|g' \
    templates/notifications/deploy-failure.md
```
