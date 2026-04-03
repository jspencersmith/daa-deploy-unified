# C:\Users\dbkr\workspace\daa-deploy-unified\scripts\health-check.sh
# Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
# Owner: @CTO-Agent | Project: DAA Infinite Synthesis


#!/bin/bash

###############################################################################
# Health Check Script - Validates all services are healthy
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="${1:-production}"
FAILED_SERVICES=()
TIMEOUT=10

log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $@${NC}"; }
log_info() { echo -e "${BLUE}ℹ️  $@${NC}"; }

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $@${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

check_url() {
  local url="$1"
  local service_name="$2"
  
  if curl -sf --connect-timeout $TIMEOUT "$url" > /dev/null 2>&1; then
    log_success "$service_name: $(curl -s -I "$url" | head -1 | xargs)"
    return 0
  else
    log_error "$service_name: Unreachable"
    FAILED_SERVICES+=("$service_name")
    return 1
  fi
}

main() {
  print_header "Health Checks - $ENVIRONMENT"
  
  log_info "Checking GitHub Pages sites..."
  check_url "https://detroitautomationacademy.com/" "Landing Page" || true
  check_url "https://blog.detroitautomationacademy.com/" "Blog" || true
  check_url "https://detroitautomationacademy.com/curriculum/" "Curriculum" || true
  
  log_info "Checking GCP Cloud Run services..."
  check_url "https://enroll.detroitautomationacademy.com/" "Enrollment Portal" || true
  check_url "https://api.detroitautomationacademy.com/health" "API Backend" || true
  check_url "https://status.detroitautomationacademy.com/health" "Status Page" || true
  
  echo ""
  if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    log_success "All services healthy"
    exit 0
  else
    log_error "${#FAILED_SERVICES[@]} service(s) unreachable:"
    for service in "${FAILED_SERVICES[@]}"; do
      echo "  - $service"
    done
    exit 1
  fi
}

main "$@"
