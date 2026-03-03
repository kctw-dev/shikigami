<!-- Notification Template: Deployment Success -->
<!-- Placeholder format: {{VARIABLE_NAME}} — replace manually or via sed/envsubst -->

## Deployment Successful

**Service**: {{SERVICE_NAME}}
**Version**: {{VERSION}}
**Environment**: {{DEPLOY_ENV}}
**Deployed at**: {{DEPLOY_TIMESTAMP}}

### Deployment Details

- **Deployer**: {{DEPLOYER}}
- **Commit**: {{COMMIT_SHA}} (`{{COMMIT_MESSAGE}}`)
- **Duration**: {{DEPLOY_DURATION}}
- **Method**: {{DEPLOY_METHOD}}

### Verification

- **Health Check**: {{HEALTH_STATUS}}
- **Golden Signals**: All within baseline
- **Rollback Plan**: {{ROLLBACK_PLAN}}

### Release Notes

{{RELEASE_NOTES}}

---

### Usage

Replace placeholders with actual values:

```bash
sed -e 's/{{SERVICE_NAME}}/shikigami/g' \
    -e 's/{{VERSION}}/v0.20.0/g' \
    -e 's/{{DEPLOY_ENV}}/production/g' \
    templates/notifications/deploy-success.md
```
