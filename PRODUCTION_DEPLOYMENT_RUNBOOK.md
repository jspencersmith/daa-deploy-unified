## C:\Users\dbkr\workspace\daa-deploy-unified\PRODUCTION_DEPLOYMENT_RUNBOOK.md
## Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
## Owner: @CTO-Agent | Project: DAA Infinite Synthesis


# PRODUCTION DEPLOYMENT RUNBOOK

**Framework:** DAA Unified Deployment v1.0.0  
**Date:** April 1, 2026  
**Status:** Ready for Execution  

---

## 📋 Pre-Deployment Phase (T-24 Hours)

### 1. Repository Push to GitHub

```bash
# Navigate to repository
cd C:\Users\dbkr\workspace\daa-deploy-unified

# Add GitHub remote
git remote add origin https://github.com/YOUR_ORG/daa-deploy-unified.git

# Push to GitHub (create repository first)
git push -u origin master

# Verify push successful
git log --oneline -5
```

**What to do:**
1. Go to https://github.com/new
2. Create repository: `daa-deploy-unified`
3. Add description: "Unified CI/CD deployment framework for Detroit Automation Academy"
4. Make repository private
5. Create repository
6. Follow instructions to push code

### 2. Verify Repository Contents

After push, verify on GitHub:
- [ ] All 16 files present
- [ ] `.github/workflows/` contains both YAML files
- [ ] `scripts/` contains all 3 shell scripts
- [ ] Documentation complete
- [ ] Git history shows initial commit

```bash
gh repo view YOUR_ORG/daa-deploy-unified
```

---

## 🔐 GitHub Secrets Configuration (T-12 Hours)

### Step 1: Access Repository Settings

GitHub Repository → Settings → Secrets and variables → Actions

### Step 2: Add Each Secret

#### Secret 1: GCP_PROJECT_ID

**Name:** `GCP_PROJECT_ID`  
**Value:** `project-9e091b7d-1e8e-4a4e-963`

```bash
# Verify project ID
gcloud config get-value project
```

#### Secret 2: GCP_SERVICE_ACCOUNT_EMAIL

**Name:** `GCP_SERVICE_ACCOUNT_EMAIL`  
**Value:** `github-actions@project-9e091b7d-1e8e-4a4e-963.iam.gserviceaccount.com`

```bash
# Verify service account exists
gcloud iam service-accounts list --format='value(email)' | grep github-actions
```

#### Secret 3: GOOGLE_CLIENT_ID

**Name:** `GOOGLE_CLIENT_ID`  
**Value:** [From Google Cloud Console]

```
Steps:
1. Go to Google Cloud Console
2. APIs & Services → Credentials
3. Find "OAuth 2.0 Client IDs" (Web application)
4. If not exists:
   - Create new OAuth consent screen (External)
   - Create new credential (OAuth 2.0 Client ID, Web application)
   - Add redirect URI: https://enroll.detroitautomationacademy.com
5. Copy Client ID value
```

#### Secret 4: REACT_APP_API_BASE_URL

**Name:** `REACT_APP_API_BASE_URL`  
**Value:** `https://api.detroitautomationacademy.com`

```bash
# Will be used by Cloud Run deployment
# After first deployment, verify with:
gcloud run services describe daa-crm-backend --region us-central1 --format 'value(status.url)'
```

#### Secret 5: SLACK_WEBHOOK_URL (Optional)

**Name:** `SLACK_WEBHOOK_URL`  
**Value:** [From Slack]

```
Steps:
1. Go to Slack workspace
2. Create channel: #deployments
3. Add Incoming Webhook:
   - Create workflow or app
   - Generate webhook URL
4. Copy webhook URL
```

### Step 3: Verify All Secrets

```bash
gh secret list

# Expected output:
# GOOGLE_CLIENT_ID
# GCP_PROJECT_ID
# GCP_SERVICE_ACCOUNT_EMAIL
# REACT_APP_API_BASE_URL
# SLACK_WEBHOOK_URL
```

---

## ✅ Pre-Flight Checks (T-6 Hours)

```bash
# Run comprehensive verification
cd C:\Users\dbkr\workspace\daa-deploy-unified
sh scripts/verify-prerequisites.sh

# Expected checks to pass:
# ✅ Git installed and configured
# ✅ gcloud CLI installed and authenticated
# ✅ GitHub CLI installed and authenticated
# ✅ Docker daemon running
# ✅ GitHub Secrets configured (all 5)
# ✅ Workload Identity pool configured
# ✅ Cloud services enabled
# ✅ Deployment repositories available
# ✅ DNS records resolving
```

If any check fails:
1. Review error message
2. Follow troubleshooting in `docs/DEPLOYMENT_GUIDE.md`
3. Re-run check
4. Do not proceed if critical checks fail

---

## 🧪 Staging Deployment (T-4 Hours)

### Deploy to Staging

```bash
# Navigate to repository
cd C:\Users\dbkr\workspace\daa-deploy-unified

# Deploy to staging environment
sh scripts/deploy.sh staging

# Monitor output:
# Expected:
# - Pre-flight checks passed
# - GitHub Actions workflows triggered
# - Watch progress: gh run list --workflow=deploy-pages.yml
```

### Monitor Staging Deployment

```bash
# Watch GitHub Actions workflows
gh run list --workflow=deploy-pages.yml --limit 1
gh run list --workflow=deploy-cloud-run.yml --limit 1

# View logs in real-time
gh run view [RUN_ID] --log

# Deployment should complete in ~10-15 minutes
```

### Verify Staging Services

```bash
# Run health checks
sh scripts/health-check.sh staging

# Expected output:
# ✅ Landing page: HEALTHY (HTTP 200)
# ✅ Blog: HEALTHY
# ✅ Curriculum: HEALTHY
# ✅ Enrollment: HEALTHY
# ✅ API Backend: HEALTHY
# ✅ Status Page: HEALTHY

# If any fail:
# 1. Check Cloud Logging for errors
# 2. Review health check details
# 3. Do not proceed to production if critical services fail
```

### Test Staging Workflows

```bash
# Test static site functionality
curl -I https://staging-daa.detroitautomationacademy.com/
curl -I https://blog-staging.detroitautomationacademy.com/

# Test dynamic services (if staging URLs available)
curl -I https://enroll-staging.detroitautomationacademy.com/
curl -I https://api-staging.detroitautomationacademy.com/health

# Verify error rate is low
gcloud logging read 'severity="ERROR"' --limit 10 --tail

# All tests should pass
```

### Staging Sign-Off

**Before proceeding to production:**

- [ ] All health checks pass
- [ ] No error rate spikes detected
- [ ] Team lead has reviewed staging
- [ ] No blockers identified
- [ ] Documentation verified
- [ ] Rollback procedure understood

---

## 🚀 Production Deployment (T+0)

### Pre-Deployment Window (T-30 Minutes)

```bash
# 1. Verify prerequisites one final time
sh scripts/verify-prerequisites.sh

# 2. Review deployment log location
echo "Deployment logs will be saved to: /tmp/daa-deployment-*.log"

# 3. Verify team is ready
echo "✅ On-call engineer: Confirm ready"
echo "✅ DevOps lead: Confirm ready"
echo "✅ VP Engineering: Confirm ready"

# 4. Notify team in Slack
# Post to #deployments: "Production deployment starting in 30 minutes..."
```

### Execute Production Deployment

```bash
# Deploy all services to production
sh scripts/deploy.sh production

# Expected output:
# ✅ Pre-flight checks passed
# ✅ Pre-deployment validation complete
# ✅ GitHub Pages deployment triggered
# ✅ GCP Cloud Run deployment triggered
# Watch progress: gh run list --workflow=deploy-pages.yml
```

**Timeline:**
- T+0:00 - Pre-flight checks begin
- T+1:00 - GitHub Pages deployment starts
- T+3:00 - GitHub Pages complete, Cloud Run deployment starts
- T+5:00 - Cloud Run deployment complete, health checks begin
- T+6:00 - Observation window starts (monitoring for errors)
- T+6:30 - Observation window complete
- T+7:00 - Final verification and notifications

### Monitor Production Deployment

```bash
# Watch GitHub Actions workflows
gh run list --workflow=deploy-pages.yml
gh run list --workflow=deploy-cloud-run.yml

# View deployment logs
tail -f /tmp/daa-deployment-*.log

# Monitor error rate (watch for spikes)
gcloud logging read 'severity="ERROR"' --limit 20 --tail

# Check deployment decisions
# Should see: "✅ Error rate normal" or "⚠️ ROLLBACK triggered"
```

### Post-Deployment Verification (T+7 Minutes)

```bash
# Run health checks
sh scripts/health-check.sh production

# Check all services
curl -I https://detroitautomationacademy.com/
curl -I https://blog.detroitautomationacademy.com/
curl -I https://enroll.detroitautomationacademy.com/
curl -I https://api.detroitautomationacademy.com/
curl -I https://status.detroitautomationacademy.com/

# Verify DNS resolution
nslookup detroitautomationacademy.com
nslookup blog.detroitautomationacademy.com
nslookup enroll.detroitautomationacademy.com

# Check Cloud Run revisions
gcloud run services list --format='table(name, status.latestRevisionName, status.url)'

# Verify error rate is low (< 0.1%)
gcloud logging read 'httpRequest.status >= 500' --limit 20
```

### Extended Monitoring (T+30 Minutes to T+1 Hour)

Continue monitoring for:
- [ ] Error rate stable (< 0.1%)
- [ ] Latency p99 < 2 seconds
- [ ] No automatic rollbacks
- [ ] Database operations normal
- [ ] Backups completed
- [ ] No PagerDuty incidents

### Success Criteria Met

✅ **Deployment Successful When:**
- All 7 services responding
- Error rate < 0.1%
- No automatic rollbacks triggered
- Slack notifications sent
- GitHub deployment status shows success
- All health checks passing
- No PagerDuty incidents

---

## 🔄 Post-Deployment Tasks

### 1. Team Communication

```
To: #deployments
Subject: ✅ Production Deployment Complete

Deployment Details:
- Started: [TIME] UTC
- Completed: [TIME] UTC
- Duration: ~7 minutes
- Status: ✅ Successful

Services Deployed:
✅ Landing page: https://detroitautomationacademy.com
✅ Blog: https://blog.detroitautomationacademy.com
✅ Curriculum: https://detroitautomationacademy.com/curriculum
✅ Enrollment: https://enroll.detroitautomationacademy.com
✅ API Backend: https://api.detroitautomationacademy.com
✅ Status Page: https://status.detroitautomationacademy.com

Health Checks: ✅ All passing
Error Rate: < 0.1%
Latency p99: 1.2 seconds

Monitoring: Active for 24 hours
Next deployment: [DATE/TIME]

No action required. System stable and operating normally.
```

### 2. Update Documentation

- [ ] Record deployment time and metrics
- [ ] Note any issues encountered
- [ ] Update deployment log
- [ ] Archive deployment logs

### 3. Schedule Follow-Up

- [ ] Team debrief: T+24 hours
- [ ] Performance review: T+7 days
- [ ] Next deployment planning: T+30 days

---

## ⚠️ Emergency Procedures

### If Automatic Rollback Triggered

**Symptoms:**
- Error rate > 1% detected
- Slack notification: "Rollback executed - error rate spike"
- PagerDuty incident: SEV-2

**Response:**
```bash
# 1. Verify rollback completed
sh scripts/deploy.sh production status

# 2. Confirm services healthy on previous version
sh scripts/health-check.sh production

# 3. Check error logs
gcloud logging read 'severity="ERROR"' --limit 50

# 4. Notify team
# Post: "Automatic rollback executed. Investigating root cause."

# 5. Investigate
# Review commit changes
# Check for configuration issues
# Look for resource exhaustion
```

### Manual Rollback (If Needed)

```bash
# Emergency rollback command
sh scripts/deploy.sh production rollback

# Expected:
# - GitHub Pages reverts to previous commit
# - Cloud Run traffic shifts to previous revision
# - Slack notification sent
# - PagerDuty incident created

# Verify rollback
sh scripts/health-check.sh production
```

### If Services Unavailable

```bash
# 1. Check service status
gcloud run services describe daa-crm-backend --region us-central1

# 2. Check Cloud Logging
gcloud logging read 'severity="ERROR"' --limit 50 --tail

# 3. Check DNS resolution
nslookup enroll.detroitautomationacademy.com

# 4. If DNS issue:
# - Verify CNAME records
# - Wait for DNS propagation
# - (usually < 5 minutes)

# 5. If service issue:
# - Check database connectivity
# - Review recent changes
# - Consider rollback

# 6. If database issue:
# - Restore from backup
# - Notify database team
```

---

## 📊 Deployment Checklist

### Pre-Deployment ✅
- [x] Framework complete and tested
- [x] Git repository initialized
- [x] Commit created and ready
- [x] Documentation finalized
- [ ] Repository pushed to GitHub
- [ ] GitHub Secrets configured
- [ ] Prerequisites verified
- [ ] Staging deployment successful

### Production ✅
- [ ] Pre-flight checks pass
- [ ] Deployment executed
- [ ] Health checks pass
- [ ] Error rate acceptable
- [ ] No rollbacks triggered
- [ ] Team notifications sent

### Post-Deployment ✅
- [ ] Services monitored for 1 hour
- [ ] Team debriefed
- [ ] Documentation updated
- [ ] Logs archived
- [ ] Lessons learned documented

---

## 📞 Contact During Deployment

- **DevOps Lead:** [Name] | Slack: @[user] | Phone: [number]
- **On-Call Engineer:** [Name] | Slack: @[user] | Phone: [number]
- **VP Engineering:** [Name] | Slack: @[user] | Phone: [number]

**Emergency Escalation:**
1. Slack #deployments with @channel
2. Page on-call engineer via PagerDuty
3. Call VP Engineering if critical

---

## ✅ Sign-Off

**Ready to proceed to production deployment:**

- [ ] Framework complete and tested
- [ ] All documentation reviewed
- [ ] Team trained and ready
- [ ] Staging deployment successful
- [ ] GitHub Secrets configured
- [ ] Prerequisites verified
- [ ] Deployment window scheduled

**Authorized by:**

DevOps Lead: __________________ Date: ________  
VP Engineering: __________________ Date: ________  

---

**Runbook Status:** ✅ Ready for Execution  
**Version:** 1.0.0  
**Last Updated:** April 1, 2026 04:35 UTC  

**Next Steps:**
1. Push repository to GitHub
2. Configure GitHub Secrets
3. Run staging deployment
4. Execute production deployment
