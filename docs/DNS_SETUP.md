## C:\Users\dbkr\workspace\daa-deploy-unified\docs\DNS_SETUP.md
## Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
## Owner: @CTO-Agent | Project: DAA Infinite Synthesis


# DNS Setup & Configuration

**Date:** April 1, 2026  
**Current Provider:** GitHub Pages + GCP Cloud DNS  

---

## Current DNS Configuration

### Primary Domain: detroitautomationacademy.com

#### A Records (GitHub Pages)
```
@    A    185.199.108.153
@    A    185.199.109.153
@    A    185.199.110.153
@    A    185.199.111.153
```

#### AAAA Records (IPv6 - GitHub Pages)
```
@    AAAA   2606:50c0:8000::153
@    AAAA   2606:50c0:8001::153
@    AAAA   2606:50c0:8002::153
@    AAAA   2606:50c0:8003::153
```

#### CNAME Records (Subdomains)
```
www      CNAME   smit4786.github.io
blog     CNAME   smit4786.github.io
```

#### TXT Records (Verification & Security)
```
@    TXT    "v=spf1 include:_spf.google.com ~all"
_dmarc    TXT    "v=DMARC1; p=quarantine; rua=mailto:dmarc@detroitautomationacademy.com"
```

---

## Subdomain Routing Strategy

### Static Sites (GitHub Pages)

| Subdomain | Service | Target | TTL |
|-----------|---------|--------|-----|
| @ (root) | Landing page | GitHub Pages (A records) | 300s |
| www | Redirect | smit4786.github.io | 300s |
| blog | Blog | smit4786.github.io | 300s |

**GitHub Pages DNS Verification:**
```bash
nslookup detroitautomationacademy.com
# Should return: 185.199.108.153, 185.199.109.153, etc.
```

### Dynamic Services (GCP Cloud Run)

| Subdomain | Service | Target (Cloud Run) | TTL |
|-----------|---------|-------|-----|
| enroll | Enrollment portal | daa-enrollment-[region].run.app | 60s |
| api | Backend API | daa-api-backend-[region].run.app | 60s |
| status | Status page | daa-status-[region].run.app | 60s |

**How to Find Cloud Run URLs:**
```bash
gcloud run services describe daa-enrollment-frontend --region us-central1 --format 'value(status.url)'
# Output: https://daa-enrollment-ww72p2xhtq-uc.a.run.app
```

**Current Configuration (Update These):**
```bash
# Login to domain registrar or Cloud DNS

# For enroll subdomain:
# Add/update CNAME record
enroll    CNAME    daa-enrollment-[region].run.app    TTL: 60s

# For api subdomain:
# Add/update CNAME record
api       CNAME    daa-api-backend-[region].run.app   TTL: 60s

# For status subdomain:
# Add/update CNAME record
status    CNAME    daa-status-[region].run.app        TTL: 60s
```

---

## Setup Instructions

### Step 1: Verify Current DNS

```bash
# Check all DNS records
dig detroitautomationacademy.com ANY

# Should show:
# - A records pointing to GitHub Pages
# - AAAA records (IPv6)
# - MX records (if email configured)
# - TXT records (SPF, DMARC)
```

### Step 2: GitHub Pages Configuration

GitHub Pages is already configured with:
- Repository: smit4786.github.io (custom domain)
- CNAME file: detroitautomationacademy.com
- SSL: Auto-renewed by GitHub
- CDN: GitHub's global CDN

**To verify:**
```bash
# Check CNAME file exists
curl https://raw.githubusercontent.com/smit4786/smit4786.github.io/main/CNAME
# Should output: detroitautomationacademy.com

# Check SSL certificate
curl -I https://detroitautomationacademy.com/
# Should show valid SSL from GitHub
```

### Step 3: GCP Cloud DNS Setup (Optional)

If moving from external DNS to Cloud DNS:

```bash
# 1. Create Cloud DNS zone
gcloud dns managed-zones create detroitautomationacademy-com \
  --dns-name=detroitautomationacademy.com. \
  --description="DNS for DAA"

# 2. Get nameservers
gcloud dns managed-zones describe detroitautomationacademy-com \
  --format='value(nameServers[*])'
# Update domain registrar with these nameservers

# 3. Create A records for GitHub Pages
gcloud dns record-sets create detroitautomationacademy.com \
  --rrdatas=185.199.108.153,185.199.109.153,185.199.110.153,185.199.111.153 \
  --ttl=300 \
  --type=A \
  --zone=detroitautomationacademy-com

# 4. Create AAAA records for IPv6
gcloud dns record-sets create detroitautomationacademy.com \
  --rrdatas=2606:50c0:8000::153,2606:50c0:8001::153,2606:50c0:8002::153,2606:50c0:8003::153 \
  --ttl=300 \
  --type=AAAA \
  --zone=detroitautomationacademy-com

# 5. Create CNAME records for subdomains
gcloud dns record-sets create blog.detroitautomationacademy.com \
  --rrdatas=smit4786.github.io. \
  --ttl=300 \
  --type=CNAME \
  --zone=detroitautomationacademy-com

gcloud dns record-sets create www.detroitautomationacademy.com \
  --rrdatas=smit4786.github.io. \
  --ttl=300 \
  --type=CNAME \
  --zone=detroitautomationacademy-com

# 6. Create Cloud Run CNAME records
gcloud dns record-sets create enroll.detroitautomationacademy.com \
  --rrdatas=ghs.googleusercontent.com. \
  --ttl=60 \
  --type=CNAME \
  --zone=detroitautomationacademy-com

# 7. Verify all records
gcloud dns record-sets list --zone=detroitautomationacademy-com
```

### Step 4: Verify DNS Propagation

```bash
# Check from multiple locations
dig @8.8.8.8 detroitautomationacademy.com
dig @1.1.1.1 detroitautomationacademy.com
dig @208.67.222.123 detroitautomationacademy.com

# Should all return GitHub Pages IPs (185.199.x.x)

# Check subdomain resolution
nslookup blog.detroitautomationacademy.com
# Should return: smit4786.github.io

nslookup enroll.detroitautomationacademy.com
# Should return: daa-enrollment-[region].run.app
```

### Step 5: Test SSL/HTTPS

```bash
# GitHub Pages (auto SSL from GitHub)
curl -I https://detroitautomationacademy.com/
curl -I https://blog.detroitautomationacademy.com/

# Cloud Run (auto SSL from Google)
curl -I https://enroll.detroitautomationacademy.com/
curl -I https://api.detroitautomationacademy.com/
curl -I https://status.detroitautomationacademy.com/

# All should return HTTP 200 with valid SSL certificate
```

---

## Automated DNS Updates

When Cloud Run services are redeployed, their URLs may change:

### Before Deployment
```bash
gcloud run services describe daa-enrollment-frontend \
  --region us-central1 \
  --format 'value(status.url)'
# Output: https://daa-enrollment-ww72p2xhtq-uc.a.run.app
```

### After Deployment (URL may change)
```bash
gcloud run services describe daa-enrollment-frontend \
  --region us-central1 \
  --format 'value(status.url)'
# Output: https://daa-enrollment-abc123defgh-uc.a.run.app (DIFFERENT!)
```

### Solution: Automated DNS Update Script

The deployment workflow includes DNS update steps:

```yaml
# In .github/workflows/deploy-cloud-run.yml
- name: Update DNS records
  run: |
    # Get new Cloud Run service URL
    NEW_URL=$(gcloud run services describe daa-enrollment-frontend \
      --region us-central1 \
      --format 'value(status.url)' | cut -d/ -f3)
    
    # Update Cloud DNS record
    gcloud dns record-sets update enroll.detroitautomationacademy.com \
      --rrdatas=$NEW_URL \
      --ttl=60 \
      --type=CNAME \
      --zone=detroitautomationacademy-com
```

---

## Troubleshooting DNS Issues

### Issue: DNS Not Resolving

```bash
# 1. Verify zone was created
gcloud dns managed-zones list

# 2. Verify records exist
gcloud dns record-sets list --zone=detroitautomationacademy-com

# 3. Check propagation (may take 24 hours)
# Use online tool: https://dnschecker.org/

# 4. Verify nameservers updated at registrar
gcloud dns managed-zones describe detroitautomationacademy-com \
  --format='value(nameServers[*])'

# 5. If using Cloud DNS, update domain registrar with new nameservers
```

### Issue: Cloud Run URL Changed, CNAME Not Updated

```bash
# 1. Get current Cloud Run URL
gcloud run services list --filter="name:daa-" --format='value(status.url)'

# 2. Update CNAME record manually
gcloud dns record-sets update enroll.detroitautomationacademy.com \
  --rrdatas=[NEW_CLOUD_RUN_URL_HOST] \
  --type=CNAME \
  --zone=detroitautomationacademy-com

# 3. Verify DNS resolution
nslookup enroll.detroitautomationacademy.com

# 4. Test HTTPS
curl -I https://enroll.detroitautomationacademy.com/
```

### Issue: SSL Certificate Invalid

```bash
# 1. Check current certificate
curl -I https://enroll.detroitautomationacademy.com/ 2>&1 | grep -i cert

# 2. If GitHub Pages issue:
# - Verify CNAME file exists in daa-public-staging repo
# - Wait 10 minutes for GitHub to renew SSL

# 3. If Cloud Run issue:
# - Cloud Run auto-generates SSL
# - Verify CNAME record points to Cloud Run domain
# - Wait 15 minutes for SSL provisioning

# 4. Check SSL details
openssl s_client -connect detroitautomationacademy.com:443
```

---

## DNS Migration Checklist

If changing DNS providers:

- [ ] Export current DNS records
- [ ] Create zone in new provider
- [ ] Add all A, AAAA, CNAME, TXT records
- [ ] Test DNS resolution from multiple locations
- [ ] Test SSL/HTTPS on all subdomains
- [ ] Update domain registrar nameservers (if applicable)
- [ ] Wait for DNS propagation (usually 24-48 hours)
- [ ] Monitor for DNS issues
- [ ] Remove old DNS records after verification

---

## Related Files

- `config/dns-config.yaml` - DNS configuration as code
- `.github/workflows/deploy-cloud-run.yml` - Automated DNS updates
- `docs/ARCHITECTURE.md` - DNS architecture overview

---

**Last Updated:** April 1, 2026  
**Current Provider:** GitHub Pages + Cloud DNS  
**Update Frequency:** As needed during deployments
