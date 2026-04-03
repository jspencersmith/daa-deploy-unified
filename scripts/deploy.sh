# C:\Users\dbkr\workspace\daa-deploy-unified\scripts\deploy.sh
# Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
# Owner: @CTO-Agent | Project: DAA Infinite Synthesis


#!/bin/bash

###############################################################################
# DAA Unified Deployment Framework - Main Entry Point
# 
# Usage:
#   sh scripts/deploy.sh production                    # Deploy all services
#   sh scripts/deploy.sh staging                       # Deploy to staging
#   sh scripts/deploy.sh production enrollment-frontend # Deploy specific service
#   sh scripts/deploy.sh rollback production           # Rollback to previous
#   sh scripts/deploy.sh status production             # Check deployment status
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/scripts"
CONFIG_DIR="$REPO_ROOT/config"
DEPLOYMENT_LOG="/tmp/daa-deployment-$(date +%Y%m%d_%H%M%S).log"

# Default values
ENVIRONMENT="${1:-production}"
COMMAND="${2:-deploy}"
SERVICE="${3:-all}"

###############################################################################
# Helper Functions
###############################################################################

log() {
  local level="$1"
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${BLUE}[${timestamp}]${NC} ${message}" | tee -a "$DEPLOYMENT_LOG"
}

log_success() {
  echo -e "${GREEN}✅ $@${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_error() {
  echo -e "${RED}❌ $@${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $@${NC}" | tee -a "$DEPLOYMENT_LOG"
}

log_info() {
  echo -e "${BLUE}ℹ️  $@${NC}" | tee -a "$DEPLOYMENT_LOG"
}

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $@${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

print_usage() {
  cat << EOF
${BLUE}Detroit Automation Academy - Unified Deployment Framework${NC}

${YELLOW}USAGE:${NC}
  sh scripts/deploy.sh [ENVIRONMENT] [COMMAND] [SERVICE]

${YELLOW}ENVIRONMENTS:${NC}
  production              Deploy to production
  staging                 Deploy to staging environment

${YELLOW}COMMANDS:${NC}
  deploy                  Deploy all services (default)
  rollback                Rollback to previous version
  status                  Check deployment status
  health-check            Run health checks only

${YELLOW}SERVICES:${NC}
  all                     Deploy all services (default)
  landing-page            Static landing page
  blog-static             Hugo blog
  curriculum-static       Curriculum content
  crm-backend             CRM backend API (Go)
  enrollment-frontend     Enrollment portal (React)
  api-backend             AI/ML backend (Python)
  status-page             Status page

${YELLOW}EXAMPLES:${NC}
  # Deploy everything to production
  sh scripts/deploy.sh production

  # Deploy to staging
  sh scripts/deploy.sh staging

  # Deploy specific service
  sh scripts/deploy.sh production deploy enrollment-frontend

  # Rollback production
  sh scripts/deploy.sh production rollback

  # Check deployment status
  sh scripts/deploy.sh production status

${YELLOW}LOGS:${NC}
  All deployment logs saved to: $DEPLOYMENT_LOG

EOF
}

###############################################################################
# Main Deployment Functions
###############################################################################

verify_prerequisites() {
  print_header "Verifying Prerequisites"
  
  local missing_tools=()
  
  # Check required tools
  for tool in git gcloud docker curl; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
      log_error "Missing required tool: $tool"
    else
      log_success "$tool installed"
    fi
  done
  
  if [ ${#missing_tools[@]} -gt 0 ]; then
    log_error "Please install missing tools: ${missing_tools[*]}"
    exit 1
  fi
  
  # Check GitHub CLI for deployment
  if [ "$COMMAND" = "deploy" ]; then
    if ! command -v gh &> /dev/null; then
      log_warning "GitHub CLI (gh) not found - manual workflow dispatch may be needed"
    fi
  fi
  
  # Check GCP project
  local gcp_project=$(gcloud config get-value project 2>/dev/null || echo "")
  if [ -z "$gcp_project" ]; then
    log_warning "GCP project not configured"
    log_info "Run: gcloud config set project PROJECT_ID"
  else
    log_success "GCP project: $gcp_project"
  fi
  
  log_success "All prerequisites verified"
}

trigger_github_workflow() {
  local workflow="$1"
  local ref="${2:-main}"
  
  print_header "Triggering GitHub Workflow: $workflow"
  
  if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is required to trigger workflows"
    log_info "Install from: https://cli.github.com/"
    return 1
  fi
  
  if [ "$ENVIRONMENT" = "staging" ]; then
    log_info "Dispatching workflow to staging environment..."
    gh workflow run "$workflow" \
      --ref main \
      -f environment=staging \
      -f service="$SERVICE" || {
      log_error "Failed to trigger workflow"
      return 1
    }
  else
    log_info "Dispatching workflow to production environment..."
    gh workflow run "$workflow" \
      --ref main \
      -f environment=production \
      -f service="$SERVICE" || {
      log_error "Failed to trigger workflow"
      return 1
    }
  fi
  
  log_success "Workflow triggered successfully"
  log_info "Watch progress: gh run list --workflow=$workflow"
}

deploy_all() {
  print_header "Deploying All Services - $ENVIRONMENT"
  
  log_info "Step 1: Deploying static sites to GitHub Pages..."
  trigger_github_workflow "deploy-pages.yml" || return 1
  
  log_info "Waiting for GitHub Pages deployment..."
  sleep 10
  
  log_info "Step 2: Deploying dynamic services to GCP Cloud Run..."
  trigger_github_workflow "deploy-cloud-run.yml" || return 1
  
  log_success "All deployment workflows triggered"
  log_info "Check status with: sh scripts/deploy.sh $ENVIRONMENT status"
}

deploy_service() {
  print_header "Deploying Service: $SERVICE - $ENVIRONMENT"
  
  case "$SERVICE" in
    landing-page|blog-static|curriculum-static)
      log_info "Deploying static site: $SERVICE"
      trigger_github_workflow "deploy-pages.yml" || return 1
      ;;
    crm-backend|enrollment-frontend|api-backend|status-page)
      log_info "Deploying dynamic service: $SERVICE"
      trigger_github_workflow "deploy-cloud-run.yml" || return 1
      ;;
    *)
      log_error "Unknown service: $SERVICE"
      return 1
      ;;
  esac
  
  log_success "Service deployment triggered"
}

check_status() {
  print_header "Deployment Status - $ENVIRONMENT"
  
  log_info "Checking GitHub Pages status..."
  if curl -sf https://detroitautomationacademy.com/ > /dev/null 2>&1; then
    log_success "Landing page: HEALTHY"
  else
    log_error "Landing page: UNHEALTHY"
  fi
  
  if curl -sf https://blog.detroitautomationacademy.com/ > /dev/null 2>&1; then
    log_success "Blog: HEALTHY"
  else
    log_error "Blog: UNHEALTHY"
  fi
  
  log_info "Checking GCP Cloud Run services..."
  
  local services=("daa-crm-backend" "daa-enrollment-frontend" "daa-api-backend")
  for service in "${services[@]}"; do
    if gcloud run services describe "$service" \
        --region us-central1 \
        --project "$(gcloud config get-value project)" \
        &> /dev/null; then
      log_success "$service: DEPLOYED"
    else
      log_warning "$service: NOT DEPLOYED"
    fi
  done
}

perform_rollback() {
  print_header "Rolling Back - $ENVIRONMENT"
  
  if [ "$ENVIRONMENT" != "production" ]; then
    log_warning "Rollback requested on $ENVIRONMENT - proceeding with caution"
  fi
  
  log_info "Step 1: Rolling back GitHub Pages..."
  log_info "Reverting to previous commit..."
  
  if git rev-parse HEAD~1 > /dev/null 2>&1; then
    local prev_commit=$(git rev-parse HEAD~1)
    log_info "Previous commit: $prev_commit"
    log_info "Would revert to: $(git log -1 --oneline $prev_commit)"
    log_warning "Manual git revert required - repository is read-only in this context"
  else
    log_error "No previous commit to rollback to"
    return 1
  fi
  
  log_info "Step 2: Rolling back GCP Cloud Run services..."
  log_warning "Manual Cloud Run traffic shift required via GCP Console"
  
  local services=("daa-crm-backend" "daa-enrollment-frontend" "daa-api-backend")
  for service in "${services[@]}"; do
    log_info "Service $service: Check Cloud Run console for previous revision"
  done
  
  log_warning "Rollback procedures documented in: docs/RUNBOOKS.md"
}

###############################################################################
# Main Logic
###############################################################################

main() {
  if [ "$#" -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_usage
    exit 0
  fi
  
  print_header "DAA Unified Deployment Framework"
  log_info "Environment: $ENVIRONMENT"
  log_info "Command: $COMMAND"
  log_info "Service: $SERVICE"
  log_info "Logs: $DEPLOYMENT_LOG"
  
  # Validate environment
  case "$ENVIRONMENT" in
    production|staging)
      log_success "Environment: $ENVIRONMENT"
      ;;
    *)
      log_error "Invalid environment: $ENVIRONMENT"
      print_usage
      exit 1
      ;;
  esac
  
  # Verify prerequisites
  verify_prerequisites || exit 1
  
  # Execute command
  case "$COMMAND" in
    deploy)
      if [ "$SERVICE" = "all" ]; then
        deploy_all
      else
        deploy_service
      fi
      ;;
    rollback)
      perform_rollback
      ;;
    status)
      check_status
      ;;
    health-check)
      "$SCRIPTS_DIR/health-check.sh" "$ENVIRONMENT"
      ;;
    *)
      log_error "Unknown command: $COMMAND"
      print_usage
      exit 1
      ;;
  esac
  
  local exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    print_header "✅ Deployment Complete"
    log_success "All operations completed successfully"
  else
    print_header "❌ Deployment Failed"
    log_error "One or more operations failed"
  fi
  
  exit $exit_code
}

# Run main function with all arguments
main "$@"
