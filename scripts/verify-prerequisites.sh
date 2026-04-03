# C:\Users\dbkr\workspace\daa-deploy-unified\scripts\verify-prerequisites.sh
# Status: 🟢 ACTIVE | Sprint: 1011 | Last Revised: 2026-04-02
# Owner: @CTO-Agent | Project: DAA Infinite Synthesis


#!/bin/bash

###############################################################################
# Pre-flight Verification Script - Validates all prerequisites for deployment
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="${1:-production}"
ERRORS=0
WARNINGS=0

log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; ((ERRORS++)); }
log_warning() { echo -e "${YELLOW}⚠️  $@${NC}"; ((WARNINGS++)); }
log_info() { echo -e "${BLUE}ℹ️  $@${NC}"; }

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $@${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

###############################################################################
# Verification Checks
###############################################################################

check_git() {
  print_header "Checking Git Configuration"
  
  if ! command -v git &> /dev/null; then
    log_error "Git is not installed"
    return 1
  fi
  log_success "Git installed"
  
  if git rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repository configured"
    log_info "Repository: $(git rev-parse --show-toplevel)"
  else
    log_warning "Not in a git repository"
  fi
}

check_gcloud() {
  print_header "Checking Google Cloud SDK"
  
  if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI is not installed"
    log_info "Install: https://cloud.google.com/sdk/docs/install"
    return 1
  fi
  log_success "gcloud CLI installed"
  
  local project=$(gcloud config get-value project 2>/dev/null || echo "")
  if [ -z "$project" ]; then
    log_error "GCP project not configured"
    log_info "Run: gcloud config set project PROJECT_ID"
  else
    log_success "GCP project: $project"
  fi
  
  if gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
    log_success "GCP authentication active"
  else
    log_error "GCP authentication not configured"
    log_info "Run: gcloud auth login"
  fi
}

check_github_cli() {
  print_header "Checking GitHub CLI"
  
  if ! command -v gh &> /dev/null; then
    log_warning "GitHub CLI (gh) not installed"
    log_info "Install: https://cli.github.com/"
    return 0
  fi
  log_success "GitHub CLI installed"
  
  if gh auth status &> /dev/null; then
    log_success "GitHub authentication active"
  else
    log_warning "GitHub authentication not configured"
    log_info "Run: gh auth login"
  fi
}

check_docker() {
  print_header "Checking Docker"
  
  if ! command -v docker &> /dev/null; then
    log_warning "Docker is not installed (needed for local testing)"
    return 0
  fi
  log_success "Docker installed"
  
  if docker ps &> /dev/null; then
    log_success "Docker daemon is running"
  else
    log_error "Docker daemon is not running"
    log_info "Start Docker and try again"
  fi
}

check_github_secrets() {
  print_header "Checking GitHub Secrets"
  
  if ! command -v gh &> /dev/null; then
    log_warning "GitHub CLI not available, skipping secrets check"
    return 0
  fi
  
  local required_secrets=(
    "GCP_PROJECT_ID"
    "GCP_SERVICE_ACCOUNT_EMAIL"
    "GOOGLE_CLIENT_ID"
    "REACT_APP_API_BASE_URL"
  )
  
  for secret in "${required_secrets[@]}"; do
    if gh secret list | grep -q "$secret"; then
      log_success "Secret configured: $secret"
    else
      log_error "Missing secret: $secret"
    fi
  done
}

check_gcp_workload_identity() {
  print_header "Checking GCP Workload Identity"
  
  if [ -z "$(gcloud config get-value project 2>/dev/null)" ]; then
    log_warning "GCP project not configured, skipping Workload Identity check"
    return 0
  fi
  
  local project=$(gcloud config get-value project 2>/dev/null)
  
  if gcloud iam service-accounts list | grep -q github-actions; then
    log_success "GitHub Actions service account exists"
  else
    log_warning "GitHub Actions service account not found"
  fi
  
  if gcloud iam workload-identity-pools list --location=global | grep -q github-actions; then
    log_success "Workload Identity pool configured"
  else
    log_warning "Workload Identity pool not configured"
  fi
}

check_cloud_services() {
  print_header "Checking GCP Service Status"
  
  if [ -z "$(gcloud config get-value project 2>/dev/null)" ]; then
    log_warning "GCP project not configured"
    return 0
  fi
  
  local services=("run" "containerregistry" "cloudbuild" "logging")
  
  for service in "${services[@]}"; do
    if gcloud services list --enabled | grep -q "$service"; then
      log_success "Service enabled: $service"
    else
      log_warning "Service not enabled: $service"
    fi
  done
}

check_deployment_repos() {
  print_header "Checking Deployment Repositories"
  
  local repos=(
    "daa-public-staging"
    "at-os-singularity"
    "oculus_core"
  )
  
  local repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  
  for repo in "${repos[@]}"; do
    if [ -d "$repo_root/$repo" ]; then
      log_success "Repository found: $repo"
    else
      log_warning "Repository not found: $repo"
    fi
  done
}

check_dns_resolution() {
  print_header "Checking DNS Resolution"
  
  local domains=(
    "detroitautomationacademy.com"
    "blog.detroitautomationacademy.com"
    "enroll.detroitautomationacademy.com"
  )
  
  for domain in "${domains[@]}"; do
    if getent hosts "$domain" > /dev/null 2>&1; then
      log_success "DNS resolves: $domain"
    else
      log_warning "DNS does not resolve: $domain"
    fi
  done
}

###############################################################################
# Summary
###############################################################################

print_summary() {
  echo ""
  print_header "Pre-flight Verification Summary"
  
  if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for deployment.${NC}"
    return 0
  elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warnings detected - deployment may proceed with caution${NC}"
    return 0
  else
    echo -e "${RED}❌ $ERRORS errors detected - deployment not recommended${NC}"
    return 1
  fi
}

###############################################################################
# Main
###############################################################################

check_git
check_gcloud
check_github_cli
check_docker
check_github_secrets
check_gcp_workload_identity
check_cloud_services
check_deployment_repos
check_dns_resolution

print_summary
exit $?
