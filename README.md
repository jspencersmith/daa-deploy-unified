## C:\Users\dbkr\workspace\daa-deploy-unified\README.md
## Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
## Owner: @CTO-Agent | Project: DAA Infinite Synthesis


# 🚀 DAA Unified Deployment Framework

**Centralized CI/CD orchestration for detroitautomationacademy.com**

Automated single-line deployment for:
- Static sites (GitHub Pages): landing page, blog, curriculum
- Dynamic services (GCP Cloud Run): enrollment CRM, backend API, status page

---

## Quick Start

### Deploy Everything
```bash
sh scripts/deploy.sh production
```

### Check Status
```bash
sh scripts/deploy.sh status production
```

### Rollback
```bash
sh scripts/deploy.sh rollback production
```

---

## Architecture

```
detroitautomationacademy.com
├── GitHub Pages (Static)
│   ├── Landing page (/)
│   ├── Blog (/blog)
│   └── Curriculum (/curriculum)
└── GCP Cloud Run (Dynamic)
    ├── Enrollment Portal (enroll.*)
    ├── Backend API (api.*)
    └── Status Page (status.*)
```

---

## Documentation

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and decisions
- **[DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - How to deploy
- **[RUNBOOKS.md](docs/RUNBOOKS.md)** - Troubleshooting
- **[DNS_SETUP.md](docs/DNS_SETUP.md)** - DNS configuration

---

## Directory Structure

```
daa-deploy-unified/
├── .github/workflows/
│   ├── deploy-pages.yml              # GitHub Pages deployment
│   ├── deploy-cloud-run.yml          # GCP Cloud Run deployment
│   └── integration-tests.yml         # Multi-service tests
├── agents/
│   └── Deployment-Agent.md           # Agent skill definition
├── scripts/
│   ├── deploy.sh                     # Main entry point
│   ├── verify-prerequisites.sh       # Pre-flight checks
│   ├── rollback.sh                   # Rollback procedures
│   └── health-check.sh               # Service health checks
├── config/
│   ├── services.yaml                 # Service definitions
│   ├── dns-config.yaml               # DNS routing rules
│   └── secrets-template.yaml         # GitHub Secrets template
├── docs/
│   ├── ARCHITECTURE.md               # System design
│   ├── DEPLOYMENT_GUIDE.md           # Usage guide
│   ├── RUNBOOKS.md                   # Troubleshooting
│   ├── DNS_SETUP.md                  # DNS configuration
│   ├── SECRETS_SETUP.md              # Secrets configuration
│   └── FAQ.md                        # Common issues
└── tests/
    ├── test-github-pages.sh          # Static site tests
    └── test-cloud-run.sh             # Dynamic service tests
```

---

## Deployment Workflow

```
Developer commits to main
    ↓
GitHub Actions triggered
    ↓
1. Pre-flight checks (GCP project, GitHub Secrets, DNS)
2. Deploy static sites (GitHub Pages) via deploy-pages.yml
3. Deploy dynamic services (GCP Cloud Run) via deploy-cloud-run.yml
4. Run integration tests
5. Monitor for errors (30s observation period)
6. Automatic rollback if error rate > 1%
7. Slack notification to #deployments
    ↓
Site live with new code
```

---

## Key Features

✅ **Single-Line Deployment** - `sh deploy.sh production`  
✅ **Fully Automated** - Merge to main triggers auto-deploy  
✅ **Secure Secrets** - GitHub Secrets, no plaintext credentials  
✅ **Multi-Service** - Coordinates GitHub Pages + GCP Cloud Run  
✅ **Health Checks** - Verifies all services responding  
✅ **Automatic Rollback** - Reverts on error detection  
✅ **Monitoring** - Slack + PagerDuty alerts  
✅ **Documented** - Architecture, runbooks, FAQs included  

---

## Prerequisites

### Local Development
- Git
- GitHub CLI (`gh`)
- Google Cloud SDK (`gcloud`)
- Docker (for testing Cloud Run images)
- bash (sh)

### GitHub
- Repository with GitHub Pages enabled
- GitHub Secrets configured (see [SECRETS_SETUP.md](docs/SECRETS_SETUP.md))
- GitHub Actions enabled

### GCP
- Project with Cloud Run enabled
- Service account with Workload Identity configured
- Container Registry (GCR) enabled

---

## GitHub Secrets Required

Configure these in GitHub repository Settings → Secrets:

```
GCP_PROJECT_ID              # Google Cloud project ID
GCP_SERVICE_ACCOUNT_EMAIL   # Service account email for Workload Identity
GOOGLE_CLIENT_ID            # OAuth client ID for enrollment portal
REACT_APP_API_BASE_URL      # Backend API URL (e.g., https://api.detroitautomationacademy.com)
SLACK_WEBHOOK_URL           # Slack webhook for #deployments notifications
PAGERDUTY_API_KEY           # PagerDuty API key (optional)
```

See [docs/SECRETS_SETUP.md](docs/SECRETS_SETUP.md) for detailed setup instructions.

---

## Supported Commands

```bash
# Deploy to production
sh scripts/deploy.sh production

# Deploy to staging
sh scripts/deploy.sh staging

# Deploy specific service
sh scripts/deploy.sh production enrollment-frontend
sh scripts/deploy.sh production blog-static
sh scripts/deploy.sh production api-backend

# Rollback to previous version
sh scripts/deploy.sh rollback production

# Check deployment status
sh scripts/deploy.sh status production

# Verify prerequisites
sh scripts/verify-prerequisites.sh

# Run health checks
sh scripts/health-check.sh production

# Manual rollback (emergency)
sh scripts/rollback.sh emergency-rollback
```

---

## Monitoring & Alerts

### Slack Notifications
- ✅ Deployment started
- ✅ Build successful
- ✅ Deployment complete
- ❌ Build failed
- ❌ Deployment failed
- ⏮️ Rollback executed

### PagerDuty Incidents
- **SEV-2:** Deployment failures
- **SEV-2:** Error rate > 1%
- **SEV-1:** Multiple service failures

---

## Rollback Procedures

### GitHub Pages
1. Identify problematic commit
2. Execute: `sh scripts/deploy.sh rollback production`
3. This reverts to previous commit and redeployes
4. ~2 minutes to complete

### GCP Cloud Run
1. Identify problematic service
2. Execute: `sh scripts/rollback.sh [service-name]`
3. Traffic shifts back to previous revision
4. ~30 seconds to complete

### Automatic Rollback
- Triggers if error rate > 1% during 30s observation period
- Triggers if p99 latency > 2s
- Logged to Cloud Logging and Slack

---

## Support & Troubleshooting

See [docs/RUNBOOKS.md](docs/RUNBOOKS.md) for:
- Common error messages and solutions
- Service dependency issues
- DNS resolution problems
- Database migration failures
- Performance degradation

---

## Status & Metrics

### Dashboard
Access deployment status: `https://status.detroitautomationacademy.com/`

### Metrics
- Deployment frequency: Every merge to main
- Deployment success rate: Target 99%+
- Time to deployment: ~5 minutes (GitHub Pages + GCP)
- Time to rollback: ~2 minutes
- Error detection: <30 seconds post-deployment

---

## Deployment Timeline

- **Phase 1-2:** Static site deployment (GitHub Pages) - ~2 min
- **Phase 3:** Dynamic service deployment (GCP Cloud Run) - ~3 min
- **Phase 4:** Health checks and verification - ~1 min
- **Phase 5:** Monitoring and observation - ~1 min
- **Total:** ~7 minutes for complete deployment

---

## Next Steps

1. Configure GitHub Secrets (see [SECRETS_SETUP.md](docs/SECRETS_SETUP.md))
2. Review deployment architecture (see [ARCHITECTURE.md](docs/ARCHITECTURE.md))
3. Read deployment guide (see [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md))
4. Test on staging: `sh scripts/deploy.sh staging`
5. Deploy to production: `sh scripts/deploy.sh production`

---

## Status

**Current Version:** 1.0.0  
**Status:** Beta (Testing)  
**Last Updated:** April 1, 2026  
**Owner:** GitHub Copilot CLI  

---

## License

Internal Detroit Automation Academy infrastructure. All rights reserved.
