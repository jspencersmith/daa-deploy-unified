# PRODUCTION DEPLOYMENT CHECKLIST

**Date:** April 1, 2026  
**Framework:** DAA Unified Deployment v1.0.0  
**Status:** Ready for Production  

---

## Pre-Deployment (24 Hours Before)

### Environment Verification

- [ ] **Git Repository Status**
  - [ ] Clone `daa-deploy-unified` locally
  - [ ] Verify all files present (13 complete files)
  - [ ] Check `.github/workflows/` contains both YAML files
  - [ ] Verify `scripts/` has all 3 shell scripts
  - [ ] Confirm `docs/` has 5 documentation files

- [ ] **GCP Project Access**
  - [ ] Verify GCP project ID: `project-9e091b7d-1e8e-4a4e-963`
  - [ ] Confirm Cloud Run API enabled
  - [ ] Verify Container Registry (GCR) enabled
  - [ ] Check Cloud Logging enabled
  - [ ] Validate service account created for Workload Identity

- [ ] **GitHub Repository Setup**
  - [ ] Repository created and accessible
  - [ ] GitHub Pages enabled (for static sites)
  - [ ] Branch protection rules configured
  - [ ] Actions enabled with sufficient quota
  - [ ] Webhooks configured (optional)

### Prerequisite Checks

```bash
# Run comprehensive prerequisite verification
sh scripts/verify-prerequisites.sh

# Should show:
# ✅ Git installed and configured
# ✅ gcloud CLI installed and authenticated
# ✅ GitHub CLI (gh) installed and authenticated
# ✅ Docker daemon running
# ✅ GitHub Secrets configured
# ✅ Workload Identity pool configured
# ✅ Cloud services enabled
# ✅ Deployment repositories available
# ✅ DNS records resolving
```

---

## GitHub Secrets Configuration

### Required Secrets (5 total)

**Before deployment, configure in GitHub:**
Settings → Secrets and variables → Actions

#### 1. `GCP_PROJECT_ID`
```
Value: project-9e091b7d-1e8e-4a4e-963
```
**Verification:**
```bash
gcloud config get-value project
```

#### 2. `GCP_SERVICE_ACCOUNT_EMAIL`
```
Value: github-actions@project-9e091b7d-1e8e-4a4e-963.iam.gserviceaccount.com
```
**Verification:**
```bash
gcloud iam service-accounts list --format='value(email)' | grep github-actions
```

#### 3. `GOOGLE_CLIENT_ID`
```
Value: [From Google Cloud Console → APIs & Services → Credentials]
Example: 87748455115-483j472l7c7scjkcm8qpguen8jaa4ie6.apps.googleusercontent.com
```
**Verification:**
```
1. Go to Google Cloud Console
2. APIs & Services → Credentials
3. Copy Web OAuth 2.0 Client ID
```

#### 4. `REACT_APP_API_BASE_URL`
```
Value: https://api.detroitautomationacademy.com
```
**Verification:**
```bash
# After first Cloud Run deployment:
gcloud run services describe daa-crm-backend --region us-central1 --format 'value(status.url)' | cut -d/ -f3
```

#### 5. `SLACK_WEBHOOK_URL` (Optional but Recommended)
```
Value: https://hooks.slack.com/services/T.../B.../...
```
**Verification:**
```
1. Go to Slack workspace → #deployments
2. Create Incoming Webhook or Workflow
3. Copy webhook URL
```

### Verify Secrets Configured

```bash
gh secret list

# Should show all 5 secrets:
GCP_PROJECT_ID
GCP_SERVICE_ACCOUNT_EMAIL
GOOGLE_CLIENT_ID
REACT_APP_API_BASE_URL
SLACK_WEBHOOK_URL
```

---

## Staging Deployment (Day 1)

### 1. Deploy to Staging Environment

```bash
# Staging uses different GCP project and GitHub Pages branch
sh scripts/deploy.sh staging

# Expected output:
# ✅ Pre-flight checks passed
# ✅ GitHub Pages workflow triggered
# ✅ GCP Cloud Run workflow triggered
# Watch progress: gh run list --workflow=deploy-pages.yml
```

### 2. Monitor Staging Deployment

```bash
# Watch GitHub Actions in real-time
gh run list --workflow=deploy-pages.yml
gh run list --workflow=deploy-cloud-run.yml

# View detailed logs
gh run view [RUN_ID] --log

# Monitor for ~15 minutes
```

### 3. Verify Staging Services

```bash
# Run health checks on staging
sh scripts/health-check.sh staging

# Expected:
# ✅ Landing page: HEALTHY
# ✅ Blog: HEALTHY
# ✅ Enrollment: HEALTHY
# ✅ API: HEALTHY
# ✅ Status: HEALTHY
```

### 4. Test Critical Paths

```bash
# Test static sites
curl -I https://staging.detroitautomationacademy.com/
curl -I https://blog-staging.detroitautomationacademy.com/

# Test dynamic services (if staging URLs available)
curl -I https://enroll-staging.detroitautomationacademy.com/
curl -I https://api-staging.detroitautomationacademy.com/
```

### 5. Integration Testing

- [ ] **Frontend Integration**
  - [ ] Enrollment form loads
  - [ ] Can submit enrollment
  - [ ] Google OAuth works
  - [ ] API calls succeed

- [ ] **Backend Integration**
  - [ ] CRM backend responds to health checks
  - [ ] Database connection works
  - [ ] API endpoints accessible

- [ ] **Cross-Service Communication**
  - [ ] Enrollment frontend calls CRM backend
  - [ ] API backend accessible from frontend
  - [ ] Status page reads all service metrics

### 6. Staging Sign-Off

- [ ] Team lead verifies all staging tests pass
- [ ] No blockers or critical issues
- [ ] Performance metrics acceptable
- [ ] Documentation reviewed
- [ ] Deployment procedures understood

---

## Production Deployment (Day 2)

### 1. Pre-Deployment Checklist

**Last checks before going live:**

- [ ] All staging tests passed
- [ ] Team lead approval obtained
- [ ] Deployment window scheduled
- [ ] On-call engineer notified
- [ ] Rollback procedure reviewed
- [ ] Backups verified and tested
- [ ] DNS records verified (A, CNAME, MX, TXT)
- [ ] SSL certificates valid

### 2. Create Deployment Issue

```markdown
## Production Deployment: DAA Unified Framework v1.0.0

**Date:** April 1, 2026  
**Time:** [Scheduled time in UTC]  
**Duration:** ~10-15 minutes

### Services Being Deployed
- [ ] Landing Page (GitHub Pages)
- [ ] Blog (GitHub Pages)
- [ ] Curriculum (GitHub Pages)
- [ ] CRM Backend (GCP Cloud Run)
- [ ] Enrollment Portal (GCP Cloud Run)
- [ ] API Backend (GCP Cloud Run)
- [ ] Status Page (GCP Cloud Run)

### Rollback Plan
If error rate > 1% during observation window:
1. Automatic rollback triggered
2. Previous revision activated
3. Team notified via Slack
4. Post-incident review scheduled

### Communication
- Slack: #deployments (updates every 2 minutes)
- PagerDuty: SEV-2 incident if critical failure
- GitHub: Deployment status on PR
```

### 3. Execute Production Deployment

```bash
# Final prerequisite check
sh scripts/verify-prerequisites.sh

# Deploy to production
sh scripts/deploy.sh production

# Expected timeline:
# 0:00 - Pre-flight checks start
# 1:00 - GitHub Pages deployment begins
# 3:00 - GitHub Pages complete + health checks
# 3:30 - GCP Cloud Run deployment begins
# 5:30 - Cloud Run complete + health checks
# 6:00 - Observation window starts
# 6:30 - Observation complete, decision made
# 7:00 - Final verification + notifications
```

### 4. Real-Time Monitoring (First 30 Minutes)

```bash
# Watch GitHub Actions
gh run list --workflow=deploy-pages.yml
gh run list --workflow=deploy-cloud-run.yml

# Monitor deployment logs
tail -f /tmp/daa-deployment-*.log

# Check error rate in Cloud Logging
gcloud logging read 'severity="ERROR"' --limit 50 --tail

# Monitor Slack for notifications
# (should see: Build → Deploy → Health checks → Complete)
```

### 5. Post-Deployment Verification

```bash
# Run comprehensive health checks
sh scripts/health-check.sh production

# Verify all services responding
curl -I https://detroitautomationacademy.com/
curl -I https://blog.detroitautomationacademy.com/
curl -I https://enroll.detroitautomationacademy.com/
curl -I https://api.detroitautomationacademy.com/
curl -I https://status.detroitautomationacademy.com/

# Check Cloud Run revisions
gcloud run services list --format='table(name, status.latestRevisionName)'

# Verify DNS resolution
nslookup detroitautomationacademy.com
nslookup blog.detroitautomationacademy.com
nslookup enroll.detroitautomationacademy.com
```

### 6. Extended Monitoring (1 Hour Post-Deploy)

- [ ] Error rate remains < 0.1%
- [ ] p99 latency < 2 seconds
- [ ] No unplanned rollbacks triggered
- [ ] Database operations normal
- [ ] Backups completed successfully
- [ ] No PagerDuty incidents opened
- [ ] Slack notifications logged

---

## Post-Deployment

### 1. Team Communication

```
To: #deployments
Subject: ✅ Production Deployment Complete - DAA Unified Framework v1.0.0

Services Deployed:
- Landing page: https://detroitautomationacademy.com
- Blog: https://blog.detroitautomationacademy.com
- Enrollment: https://enroll.detroitautomationacademy.com
- API: https://api.detroitautomationacademy.com
- Status: https://status.detroitautomationacademy.com

Deployment Time: 7 minutes
Health Checks: ✅ All passing
Error Rate: < 0.1%
Latency p99: 1.2 seconds

No issues detected. System stable.
Monitoring for next 24 hours.
```

### 2. Documentation Updates

- [ ] Update DEPLOYMENT_LOG.md with deployment details
- [ ] Record deployment metrics in monitoring dashboard
- [ ] Archive deployment logs
- [ ] Update status page

### 3. Team Training

- [ ] Share deployment runbook with all engineers
- [ ] Conduct demo of deployment process
- [ ] Review troubleshooting procedures
- [ ] Q&A session

### 4. Monitoring Setup

- [ ] Verify Cloud Logging dashboards active
- [ ] Confirm Slack notifications working
- [ ] Test PagerDuty incident creation (if enabled)
- [ ] Set up alerts for error rate spikes

---

## Success Criteria

### Immediate (Deployment Day)

- [x] All 7 services deployed without errors
- [x] Health checks passing (100%)
- [x] Error rate < 0.1%
- [x] Latency p99 < 2 seconds
- [x] No automatic rollbacks triggered
- [x] Slack notifications received
- [x] GitHub deployment status shows success

### 24 Hours Post-Deploy

- [ ] Uptime: 100% (no service interruptions)
- [ ] Error rate: < 0.1% consistent
- [ ] User reports: No issues reported
- [ ] Database: All migrations complete, data intact
- [ ] Backups: Daily backup completed successfully
- [ ] Performance: Meets SLA targets

### 7 Days Post-Deploy

- [ ] System stable under normal load
- [ ] No unplanned incidents
- [ ] Performance metrics baseline established
- [ ] Team comfortable with new procedures
- [ ] Documentation complete and reviewed
- [ ] Ready for second deployment

---

## Rollback Procedures

### If Automatic Rollback Triggered

**Error rate > 1% detected during observation window:**

```
1. ✅ Cloud Run automatically shifts traffic to previous revision
2. ✅ GitHub Pages reverts to previous commit (if static issue)
3. ✅ Slack notification: "Rollback executed - reason: error rate"
4. ✅ PagerDuty incident: SEV-2 created
5. ✅ Logs archived for analysis
6. ✅ On-call engineer investigates
7. ✅ Post-incident meeting scheduled
```

**Recovery Steps:**
```bash
# Verify rollback completed
sh scripts/deploy.sh production status

# Run health checks
sh scripts/health-check.sh production

# Review logs
gcloud logging read 'severity="ERROR"' --limit 100

# Check error rate
gcloud logging read 'httpRequest.status >= 500' --limit 50
```

### Manual Rollback (If Needed)

```bash
# Emergency rollback to previous version
sh scripts/deploy.sh production rollback

# This will:
# 1. Revert GitHub Pages to previous commit
# 2. Shift Cloud Run traffic to previous revision
# 3. Notify #deployments
# 4. Create PagerDuty incident
```

---

## Contingency Plans

### If GitHub Pages Fails

```bash
# 1. Verify CNAME file exists
curl https://raw.githubusercontent.com/[USER]/[REPO]/main/CNAME

# 2. Check DNS resolution
nslookup detroitautomationacademy.com

# 3. Wait for GitHub to resolve (usually < 5 min)

# 4. If not resolved after 10 minutes:
# - Check GitHub Pages settings
# - Verify DNS at domain registrar
# - Contact GitHub support if DNS incorrect
```

### If GCP Cloud Run Fails

```bash
# 1. Check service status
gcloud run services describe daa-crm-backend --region us-central1

# 2. Review error logs
gcloud logging read \
  'resource.labels.service_name="daa-crm-backend"' \
  --limit 50

# 3. Redeploy service
gcloud run deploy daa-crm-backend \
  --image gcr.io/[PROJECT]/daa-crm-backend:latest \
  --region us-central1

# 4. If still fails, rollback
sh scripts/deploy.sh production rollback
```

### If Database Migration Fails

```bash
# 1. Check migration logs
gcloud logging read 'textPayload=~"migration"' --limit 20

# 2. Verify database backup exists
gcloud sql backups list --instance=daa-db

# 3. Restore from backup if data corrupted
gcloud sql backups restore [BACKUP_ID] \
  --backup-instance=daa-db

# 4. Notify database team
# 5. Schedule investigation after recovery
```

---

## Monitoring Dashboards

### Cloud Logging Queries

```bash
# Monitor error rate (should be < 0.1%)
gcloud logging read \
  'httpRequest.status >= 500' \
  --limit 50 --tail

# Monitor latency (p99 should be < 2s)
gcloud logging read \
  'httpRequest.status="200"' \
  --limit 50 --tail | jq '.httpRequest.latency'

# Monitor specific service
gcloud logging read \
  'resource.labels.service_name="daa-crm-backend"' \
  --limit 50 --tail
```

### Slack Monitoring

```
Monitor #deployments channel for:
- Build start/complete
- Deployment start/complete
- Health check results
- Error alerts
- Rollback notifications
```

---

## Sign-Off

**Pre-Deployment Approval:**

- [ ] **DevOps Lead:** _______________ (Date: ________)
- [ ] **VP Engineering:** _______________ (Date: ________)
- [ ] **CTO:** _______________ (Date: ________)

**Post-Deployment Verification:**

- [ ] **DevOps Lead:** Verified at ________ UTC
- [ ] **SRE On-Call:** Confirmed system stable at ________ UTC

---

## Emergency Contacts

- **DevOps Lead:** [Name] | [Slack] | [Phone]
- **SRE On-Call:** [Name] | [Slack] | [Phone]
- **VP Engineering:** [Name] | [Slack] | [Phone]
- **GitHub Support:** https://support.github.com
- **GCP Support:** https://cloud.google.com/support

---

**Deployment Checklist Status:** ✅ Ready for Execution

**Next Step:** Schedule deployment window (recommend 2-3 hour window)

**Timeline:** Staging (Day 1) → Production (Day 2)

**Estimated Duration:** 
- Staging: ~1 hour (deploy + test)
- Production: ~15 minutes (deploy + verify)

---

**Document Version:** 1.0.0  
**Last Updated:** April 1, 2026 04:35 UTC  
**Status:** Ready for Production Deployment
