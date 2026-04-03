## C:\Users\dbkr\workspace\daa-deploy-unified\docs\ARCHITECTURE.md
## Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
## Owner: @CTO-Agent | Project: DAA Infinite Synthesis


# DAA Unified Deployment Framework - Architecture

**Version:** 1.0.0  
**Date:** April 1, 2026  
**Status:** Beta

---

## Executive Summary

The DAA Unified Deployment Framework provides **single-line deployment** orchestration for Detroit Automation Academy's web presence across two deployment platforms:

1. **GitHub Pages** - Static content (landing page, blog, curriculum)
2. **GCP Cloud Run** - Dynamic services (enrollment CRM, backend APIs)

This hybrid architecture optimizes for **cost efficiency** ($200-300/month) while maintaining **scalability** and **zero-downtime deployments**.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                  Developer Workflow                              │
│  Commit to main → GitHub Actions → Multi-Service Deployment    │
└─────────────────────────────────────────────────────────────────┘
          ↓
┌─────────────────────────────────────────────────────────────────┐
│              Unified Deployment Framework                        │
│  daa-deploy-unified Repository                                  │
│  ├── .github/workflows/                                         │
│  │   ├── deploy-pages.yml (Static)                              │
│  │   └── deploy-cloud-run.yml (Dynamic)                         │
│  └── scripts/deploy.sh (Orchestrator)                           │
└─────────────────────────────────────────────────────────────────┘
          ↓           ↓           ↓
    ┌─────┴────┬──────┴──────┬────┴─────┐
    ↓          ↓             ↓          ↓
 [GitHub]   [GCP Cloud]  [DNS]    [Monitoring]
 [Pages]    [Run]        [CNAME]  [Slack/PD]
```

---

## Deployment Targets

### Static Content (GitHub Pages - $0/month)

| Service | Domain | Source Repo | Build Process | Purpose |
|---------|--------|-----------|---|---|
| **Landing Page** | detroitautomationacademy.com | daa-public-staging | HTML/CSS | Main website |
| **Blog** | blog.detroitautomationacademy.com | daa-public-staging | Hugo + Markdown | Technical blog |
| **Curriculum** | detroitautomationacademy.com/curriculum | daa-public-staging | HTML/CSS | Course content |

**Deployment Strategy:**
- Build: `hugo build` + static file copy
- Deploy: GitHub Pages artifact upload
- CDN: Global GitHub CDN (automatic)
- Health Check: HTTPS + SSL verification

### Dynamic Services (GCP Cloud Run - $200-300/month)

| Service | Domain | Runtime | Port | Purpose | Cost |
|---------|--------|---------|------|---------|------|
| **CRM Backend** | api.detroitautomationacademy.com | Go | 8080 | Backend API for enrollment | $50-100 |
| **Enrollment Portal** | enroll.detroitautomationacademy.com | Node.js | 80 | React enrollment form | $50-100 |
| **API Backend** | api.detroitautomationacademy.com | Python/Ray | 8011 | ML/AI backend | $50-100 |
| **Status Page** | status.detroitautomationacademy.com | Node.js | 8080 | System status dashboard | $20-30 |

**Deployment Strategy:**
- Build: Docker image → Google Container Registry
- Deploy: Cloud Run with canary (10% traffic)
- Observe: 30-second error rate monitoring
- Auto-Rollback: If error rate > 1% or p99 > 2s

---

## Deployment Phases

### Phase 1: Pre-flight Checks (Parallel)
```
- Verify GCP project credentials ✓
- Validate GitHub Secrets present ✓
- Check DNS records resolve ✓
- Confirm service account permissions ✓
```

### Phase 2: Build (Parallel)
```
GitHub Pages:                    GCP Cloud Run:
├── Build Hugo blog              ├── Build CRM backend (Go)
├── Copy static files            ├── Build enrollment frontend (Node)
└── Prepare deployment            ├── Build API backend (Python)
                                 └── Push to GCR
```

### Phase 3: Deploy (Staged)
```
1. Deploy static sites (GitHub Pages) - ~2 minutes
2. Deploy backend services (CRM, API) - ~1 minute
3. Deploy frontend services (Enrollment) - ~1 minute
4. Deploy status page - ~30 seconds
```

### Phase 4: Verify (Parallel)
```
- Health check all services ✓
- Monitor error rates ✓
- Verify DNS resolution ✓
- Confirm database migrations ✓
```

### Phase 5: Observe (30 seconds)
```
- Monitor Cloud Logging for errors
- Check error rate (should be < 0.1%)
- Verify p99 latency < 2 seconds
- Auto-rollback if thresholds exceeded
```

---

## Key Architectural Decisions

### Decision 1: GitHub Pages + GCP Hybrid (NOT All-GCP)

**Considered:**
- **Option A:** All on GCP ($100-500/month) ❌
- **Option B:** All on GitHub Pages (static only) ❌
- **Option C:** Hybrid - GitHub Pages (static) + GCP (dynamic) ✅

**Rationale:**
- GitHub Pages perfect for static content (free, fast, version-controlled)
- GCP Cloud Run needed for dynamic services (APIs, enrollment portal)
- Hybrid approach: Best cost ($200-300) + flexibility

**Trade-off:** Separate deployment pipelines vs. unified UI
- **Benefit:** Optimize each platform independently
- **Mitigation:** Single `deploy.sh` script orchestrates both

### Decision 2: Canary Deployment (10% Traffic)

**Considered:**
- **Option A:** Blue-green (100% cutover) ❌ (higher risk)
- **Option B:** Rolling deployment ❌ (complex rollback)
- **Option C:** Canary (10% → 100% if healthy) ✅

**Rationale:**
- 10% traffic validates new version on real users
- 30-second observation window catches errors early
- Easy rollback (shift traffic back to previous revision)

### Decision 3: Workload Identity for GCP Auth

**Considered:**
- **Option A:** Service account keys (manual rotation) ❌
- **Option B:** Workload Identity (OIDC tokens) ✅

**Rationale:**
- No secrets in GitHub (more secure)
- Automatic token rotation (better than manual keys)
- Native GCP integration
- Industry standard (OIDC)

---

## DNS Architecture

### Primary Route (GitHub Pages)

```
detroitautomationacademy.com
  A → 185.199.108.153
  A → 185.199.109.153 (GitHub Pages IPv4)
  A → 185.199.110.153
  A → 185.199.111.153
  
  AAAA → 2606:50c0:8000::153 (GitHub Pages IPv6)
  AAAA → 2606:50c0:8001::153
  AAAA → 2606:50c0:8002::153
  AAAA → 2606:50c0:8003::153
```

### Subdomain Routing (Hybrid)

```
blog.detroitautomationacademy.com
  CNAME → smit4786.github.io (GitHub Pages)

enroll.detroitautomationacademy.com
  CNAME → daa-enrollment-[region].run.app (GCP Cloud Run)

api.detroitautomationacademy.com
  CNAME → daa-api-backend-[region].run.app (GCP Cloud Run)

status.detroitautomationacademy.com
  CNAME → daa-status-[region].run.app (GCP Cloud Run)
```

### DNS Advantages

- **GitHub Pages:** Automatic DNS verification + SSL renewal
- **GCP Cloud Run:** Dynamic DNS updates via workflow
- **Automatic Failover:** If Cloud Run down, static sites still accessible
- **No Single Point of Failure:** GitHub + GCP both required to break site

---

## Service Dependencies

```
Enrollment Frontend (React)
    ↓ (requires)
CRM Backend (Go)
    ↓ (requires)
API Backend (Python)

Status Page
    ↓ (monitors)
All other services
```

**Deployment Order:**
1. Deploy CRM Backend first (other services depend on it)
2. Deploy API Backend (independent, but monitored)
3. Deploy Enrollment Frontend (depends on CRM Backend)
4. Deploy Status Page (independent, reads metrics)

---

## Monitoring & Alerts

### Cloud Logging Queries

```yaml
Error Rate:
  filter: resource.type="cloud_run_revision" severity="ERROR"
  threshold: 1% per 30s
  action: Automatic rollback + Slack alert

Latency:
  filter: protoPayload.status != 200
  threshold: p99 > 2000ms
  action: Automatic rollback + Slack alert

Failed Health Checks:
  filter: httpRequest.status >= 500
  threshold: 5+ per minute
  action: Slack alert + PagerDuty incident
```

### Slack Notifications

- ✅ Deployment started
- ✅ Build successful
- ✅ Deployment complete
- ❌ Build failed
- ❌ Deployment failed
- ⏮️ Rollback executed

### PagerDuty Integration

- **SEV-2:** Deployment failures
- **SEV-2:** Error rate > 1%
- **SEV-1:** Multiple service failures

---

## Rollback Procedures

### GitHub Pages Rollback

1. Identify problematic commit
2. Execute: `git revert [commit-hash]`
3. Push to main → automatic redeploy
4. ~2 minutes to complete

### GCP Cloud Run Rollback

1. Cloud Run keeps previous 3 revisions
2. Execute: `gcloud run deploy [service] --revision-suffix=previous`
3. Or use Cloud Console to shift traffic
4. ~30 seconds to complete

### Automatic Rollback Triggers

```
if error_rate > 1% AND observation_time = 30s
  then ROLLBACK to previous revision
  and NOTIFY #deployments
  
if p99_latency > 2000ms AND observation_time = 30s
  then ROLLBACK to previous revision
  and NOTIFY PagerDuty
```

---

## Performance Characteristics

### Build Times
- Hugo blog build: ~20 seconds
- Static files preparation: ~10 seconds
- Docker build (Go backend): ~60 seconds
- Docker build (Node frontend): ~45 seconds
- Docker build (Python API): ~120 seconds

### Deployment Times
- GitHub Pages deployment: ~2 minutes (includes DNS propagation)
- Cloud Run deployment: ~3 minutes (includes image push + health checks)
- Health check validation: ~1 minute
- Observation window: ~30 seconds
- **Total deployment time: ~6-7 minutes**

### Rollback Times
- GitHub Pages: ~2 minutes
- Cloud Run: ~30 seconds

### Performance SLAs
- **Availability:** 99.99% uptime
- **Latency:** p50 < 200ms, p99 < 2 seconds
- **Error Rate:** < 0.1% (5xx errors)
- **Deployment Success:** > 99% (with automatic rollback)

---

## Security Architecture

### Secrets Management

```
GitHub Secrets (encrypted):
├── GCP_PROJECT_ID
├── GCP_SERVICE_ACCOUNT_EMAIL
├── GOOGLE_CLIENT_ID
├── REACT_APP_API_BASE_URL
└── SLACK_WEBHOOK_URL

Injected at runtime:
├── Workflow env variables
└── Cloud Run environment variables
```

### Authentication

```
GitHub Actions → Workload Identity → GCP
  (OIDC token)        (OIDC provider)   (Service account)
  
No service account keys stored anywhere
No secrets committed to git
Automatic token rotation
```

### Authorization

```
Workload Identity Service Account Roles:
├── roles/run.admin (deploy to Cloud Run)
├── roles/storage.admin (manage GCR)
├── roles/logging.logWriter (write logs)
└── roles/monitoring.metricWriter (write metrics)
```

---

## Cost Breakdown

### Monthly Costs

| Service | Component | Cost | Notes |
|---------|-----------|------|-------|
| **Static Sites** | GitHub Pages | $0 | Free tier |
| **CRM Backend** | Cloud Run | $50-100 | ~1000 req/day |
| **Enrollment Frontend** | Cloud Run | $50-100 | ~500 req/day |
| **API Backend** | Cloud Run | $50-100 | ~2000 req/day |
| **Status Page** | Cloud Run | $20-30 | ~100 req/day |
| **Container Registry** | GCR Storage | $10-20 | ~5 images × 500MB |
| **Logging** | Cloud Logging | $5-10 | ~100MB/month |
| **Total** | | **$200-300** | **vs $500 all-GCP** |

---

## Disaster Recovery

### Backup Strategy

```
Daily Snapshots:
├── GitHub Pages: Version control (infinite history)
├── Database: GCP snapshots (7-day retention)
└── Static content: Cloud Storage (versioned)

Restore Procedure:
1. GitHub Pages: git revert to any previous commit
2. Database: gcloud sql backups restore [backup-id]
3. Cloud Run: Shift traffic to previous revision
```

### Business Continuity

```
If GitHub down:
  - Cloud Run services still accessible
  - Enrollment portal still works
  - API services still accessible
  - Status: DEGRADED (no static sites)

If GCP down:
  - Static sites still work (GitHub Pages)
  - Enrollment stopped (no backend)
  - API unavailable
  - Status: DEGRADED (static only)

If both down:
  - Status: OUTAGE (all services)
  - Recovery: ~15 minutes (redeploy from git)
```

---

## Scalability Path

### Current Capacity

- **Static sites:** Unlimited (CDN-backed)
- **Enrollment:** ~100 concurrent users
- **API Backend:** ~1000 req/s capacity
- **Total users:** ~5,000 concurrent

### Scaling to 10x

1. **Increase Cloud Run limits:**
   - Memory: 512Mi → 2Gi
   - CPU: 1 → 4
   - Max instances: 10 → 50

2. **Add database replicas:**
   - Read replicas in us-east1, eu-west1
   - Connection pooling via Cloud SQL Proxy

3. **Implement caching:**
   - Redis Cache for hot data
   - Cloud CDN for static assets

4. **Cost impact:** $200-300 → $800-1200/month

---

## Future Enhancements

### Q2 2026
- [ ] Multi-region deployment (us-west1, eu-west1)
- [ ] Automated performance testing
- [ ] Database sharding for API backend

### Q3 2026
- [ ] Kubernetes migration (GKE)
- [ ] Terraform infrastructure as code
- [ ] Advanced monitoring dashboards

### Q4 2026
- [ ] Multi-cloud deployment (AWS, Azure)
- [ ] Federated learning for ML models
- [ ] Advanced anomaly detection

---

## Related Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - How to deploy
- [RUNBOOKS.md](RUNBOOKS.md) - Troubleshooting procedures
- [DNS_SETUP.md](DNS_SETUP.md) - DNS configuration details
- [SECRETS_SETUP.md](SECRETS_SETUP.md) - GitHub Secrets setup

---

**Document Status:** Ready for Production  
**Last Updated:** April 1, 2026 04:15 UTC
