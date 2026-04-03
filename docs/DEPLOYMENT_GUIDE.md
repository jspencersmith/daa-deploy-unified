## C:\Users\dbkr\workspace\daa-deploy-unified\docs\DEPLOYMENT_GUIDE.md
## Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
## Owner: @CTO-Agent | Project: DAA Infinite Synthesis


# Deployment Guide - Detroit Automation Academy

**Quick Reference:** `sh scripts/deploy.sh production`

---

## Table of Contents

1. [Pre-Deployment Setup](#pre-deployment-setup)
2. [Deployment Commands](#deployment-commands)
3. [Monitoring Deployment](#monitoring-deployment)
4. [Troubleshooting](#troubleshooting)
5. [Emergency Procedures](#emergency-procedures)

---

## Pre-Deployment Setup

### Initial Setup (One-Time)

```bash
# 1. Configure GitHub Secrets (in GitHub repository Settings)
# Required secrets:
#   - GCP_PROJECT_ID
#   - GCP_SERVICE_ACCOUNT_EMAIL
#   - GOOGLE_CLIENT_ID
#   - REACT_APP_API_BASE_URL
#   - SLACK_WEBHOOK_URL (optional)

# 2. Verify prerequisites
sh scripts/verify-prerequisites.sh

# 3. Configure GCP
gcloud config set project PROJECT_ID
gcloud auth login

# 4. Configure GitHub CLI
gh auth login

# 5. Clone source repositories
git clone https://github.com/YOUR_ORG/daa-public-staging
git clone https://github.com/YOUR_ORG/at-os-singularity
git clone https://github.com/YOUR_ORG/oculus_core
```

### Before Each Deployment

```bash
# 1. Verify prerequisites
sh scripts/verify-prerequisites.sh

# 2. Check current status
sh scripts/deploy.sh production status

# 3. Review recent changes
git log --oneline -5
```

---

## Deployment Commands

### Deploy All Services (Production)

```bash
# Deploy everything to production
sh scripts/deploy.sh production

# This triggers:
# 1. GitHub Pages deployment (static sites)
# 2. GCP Cloud Run deployment (dynamic services)
# 3. Health checks for all services
# 4. Slack notifications
```

### Deploy to Staging

```bash
# Test deployment in staging environment
sh scripts/deploy.sh staging

# Staging environment:
# - Uses gh-pages-staging branch for GitHub Pages
# - Uses staging GCP project
# - Allows testing without affecting production
```

### Deploy Specific Service

```bash
# Deploy only blog
sh scripts/deploy.sh production deploy blog-static

# Deploy only enrollment portal
sh scripts/deploy.sh production deploy enrollment-frontend

# Available services:
#   - landing-page
#   - blog-static
#   - curriculum-static
#   - crm-backend
#   - enrollment-frontend
#   - api-backend
#   - status-page
```

### Check Deployment Status

```bash
# Check if services are healthy
sh scripts/deploy.sh production status

# Output:
#   Landing page: HEALTHY
#   Blog: HEALTHY
#   Enrollment: HEALTHY
#   API: HEALTHY
#   Status: HEALTHY
```

### Rollback to Previous Version

```bash
# Rollback all services
sh scripts/deploy.sh production rollback

# This will:
# 1. Revert GitHub Pages to previous commit
# 2. Shift Cloud Run traffic back to previous revision
# 3. Notify #deployments in Slack
# 4. Create incident in PagerDuty (if configured)
```

---

## Monitoring Deployment

### Real-Time Monitoring

```bash
# Watch GitHub Actions workflows
gh run list --workflow=deploy-pages.yml
gh run list --workflow=deploy-cloud-run.yml

# View full output of a run
gh run view [run-id] --log
```

### Check Logs

```bash
# Deployment logs saved to:
/tmp/daa-deployment-YYYYMMDD_HHMMSS.log

# View recent deployments
tail -f /tmp/daa-deployment-*.log
```

### Monitor Services

```bash
# Continuous health check
while true; do
  sh scripts/health-check.sh production
  sleep 30
done
```

### Cloud Logging (GCP)

```bash
# Monitor Cloud Run errors in real-time
gcloud logging read \
  'resource.type="cloud_run_revision" severity="ERROR"' \
  --limit 50 \
  --format json

# Monitor specific service
gcloud logging read \
  'resource.labels.service_name="daa-crm-backend"' \
  --limit 50 \
  --tail
```

---

## Troubleshooting

### Deployment Fails During Build

**Symptom:** Build phase fails for Docker images

**Solution:**
```bash
# 1. Check Docker daemon is running
docker ps

# 2. Verify GCR credentials
gcloud auth configure-docker

# 3. Check available disk space
df -h

# 4. Try manual build
cd at-os-singularity/apps/academy/crm/backend
docker build -t test:latest .
```

### Health Checks Fail Post-Deploy

**Symptom:** Services report unhealthy after deployment

**Solution:**
```bash
# 1. Check DNS resolution
nslookup enroll.detroitautomationacademy.com
nslookup api.detroitautomationacademy.com

# 2. Check Cloud Run service is running
gcloud run services describe daa-crm-backend --region us-central1

# 3. Check service logs
gcloud logging read \
  'resource.labels.service_name="daa-crm-backend"' \
  --limit 20 \
  --tail

# 4. Test service URL directly
curl -v https://api.detroitautomationacademy.com/health

# 5. If still failing, rollback
sh scripts/deploy.sh production rollback
```

### GitHub Pages Not Updating

**Symptom:** Static sites not showing new content

**Solution:**
```bash
# 1. Check build artifact
gh run view [run-id] --log | grep "Upload Pages artifact"

# 2. Verify CNAME file exists
ls -la deployment/CNAME

# 3. Check deployment completed
gh run view [run-id] --status

# 4. Wait for GitHub Pages to build (~1 minute)
# Then hard refresh browser (Ctrl+Shift+R)

# 5. If still not updated, manual redeploy
gh workflow run deploy-pages.yml --ref main
```

### Enrollment Frontend Not Connecting to Backend

**Symptom:** Enrollment form shows "Cannot connect to API"

**Solution:**
```bash
# 1. Verify API backend is running
curl -v https://api.detroitautomationacademy.com/health

# 2. Check frontend environment variables
# In GitHub Secrets:
#   REACT_APP_API_BASE_URL should be set correctly

# 3. Check enrollment service logs
gcloud logging read \
  'resource.labels.service_name="daa-enrollment-frontend"' \
  --limit 20

# 4. Manually redeploy frontend with correct env vars
gh workflow run deploy-cloud-run.yml \
  -f service=enrollment-frontend

# 5. Wait 2 minutes for deployment, then test
curl https://enroll.detroitautomationacademy.com/
```

### DNS Not Resolving

**Symptom:** Domain names not resolving or resolving to wrong IP

**Solution:**
```bash
# 1. Check current DNS records
nslookup detroitautomationacademy.com
nslookup blog.detroitautomationacademy.com
nslookup enroll.detroitautomationacademy.com

# 2. Verify GitHub Pages DNS (should show GitHub IPs)
dig detroitautomationacademy.com

# 3. Verify Cloud Run DNS (should show CNAME)
dig enroll.detroitautomationacademy.com

# 4. Clear local DNS cache (macOS)
sudo dscacheutil -flushcache

# 5. Clear local DNS cache (Linux)
sudo systemctl restart systemd-resolved

# 6. Wait for DNS propagation (up to 24 hours)
# Use online tools:
#   https://mxtoolbox.com/
#   https://dnschecker.org/
```

### Out of Quota (GCP)

**Symptom:** Deployment fails with "quota exceeded" error

**Solution:**
```bash
# 1. Check current quotas
gcloud compute project-info describe --project=PROJECT_ID

# 2. Request quota increase in GCP Console
# Navigation: Quotas & System Limits

# 3. Common limits to increase:
#   - Cloud Run instances (default: 1000)
#   - Cloud Run vCPU (default: 1000)
#   - Compute Engine API (if scaling to GKE)

# 4. Temporary mitigation: reduce max-instances
gcloud run deploy daa-crm-backend \
  --max-instances 5
```

---

## Emergency Procedures

### Immediate Rollback (When All Else Fails)

```bash
# 1. Manual GitHub Pages rollback
cd daa-public-staging
git revert HEAD
git push origin main
# GitHub Actions will auto-deploy

# 2. Manual Cloud Run rollback
gcloud run deploy daa-crm-backend \
  --region us-central1 \
  --revision-suffix previous

# 3. Notify team
echo "Rollback executed at $(date)" | slack_notify
```

### Complete Site Recovery

```bash
# 1. If site completely down:
cd daa-deploy-unified

# 2. Verify Git is in good state
git status
git log -1

# 3. Redeploy from scratch
sh scripts/deploy.sh production

# 4. Monitor closely
sh scripts/deploy.sh production status

# 5. If still broken, check logs
gcloud logging read 'severity="ERROR"' --limit 50 --tail
```

### Database Issues

```bash
# If database is corrupted:
# 1. Check backups exist
gcloud sql backups list --instance=daa-db

# 2. Restore from backup
gcloud sql backups restore [BACKUP_ID] \
  --backup-instance=daa-db

# 3. Verify data integrity
# Run test queries against recovered database

# 4. Resume traffic to healthy database
gcloud sql instances patch daa-db --clear-denied-networks
```

---

## Post-Deployment Verification

### Immediate Checks (After Deploy)

```bash
# 1. Run health checks
sh scripts/deploy.sh production status

# 2. Verify all services healthy
sh scripts/health-check.sh production

# 3. Check logs for errors
gcloud logging read 'severity="ERROR"' --limit 10

# 4. Monitor metrics
gcloud monitoring metrics-descriptors list

# 5. Verify DNS
nslookup detroitautomationacademy.com
```

### Extended Monitoring (1 hour post-deploy)

```bash
# 1. Monitor error rate (should be < 0.1%)
gcloud logging read \
  'httpRequest.status >= 500' \
  --format 'value(timestamp, httpRequest.latency)'

# 2. Monitor latency (p99 should be < 2s)
# Use Cloud Trace dashboard

# 3. Check database connections
# Use Cloud SQL dashboard

# 4. Verify backup jobs ran
gcloud sql backups list --instance=daa-db

# 5. Review deployment logs
gh run view [run-id] --log | tail -100
```

---

## Success Indicators

✅ **Deployment Succeeded When:**
- All health checks pass
- Error rate < 0.1%
- No PagerDuty incidents opened
- Slack notifications show success
- Users can access services
- Database migrations completed
- Backups created successfully

---

## Need Help?

- **Technical Issues:** See [RUNBOOKS.md](RUNBOOKS.md)
- **Architecture Questions:** See [ARCHITECTURE.md](ARCHITECTURE.md)
- **DNS Issues:** See [DNS_SETUP.md](DNS_SETUP.md)
- **Secrets Setup:** See [SECRETS_SETUP.md](SECRETS_SETUP.md)
- **Emergency Contact:** Slack #deployments channel

---

**Last Updated:** April 1, 2026  
**Version:** 1.0.0
