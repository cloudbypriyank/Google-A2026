#!/bin/bash
set -euo pipefail

# ==========================================================
# IMPORTANT: EDIT BEFORE RUNNING
# ==========================================================
# This lab script is a template. Before using it in your project,
# replace the following values to match your actual lab environment:
#
# REQUIRED VALUES TO CHECK / UPDATE:
#   - PROJECT_ID
#   - REGION
#   - ZONE
#   - HUB_NAME
#   - VPC1_NAME
#   - VPC2_NAME
#   - VPC1 subnet export range: 10.1.2.0/24
#   - VPC2 subnet export range: 10.3.3.0/24
#   - PSC_IP (choose a free IP inside vpc2-ncc-subnet1)
#   - SQL_INSTANCE_NAME (if using PSC + Cloud SQL)
#
# NOTE:
#   Names, regions, and subnet ranges are usually different in every
#   Google Cloud lab environment. Do not run this script without
#   checking that your lab resources match these values.
# ==========================================================

# ==========================================================
# Establish VPC to VPC Connectivity using NCC
# ==========================================================
# This script follows the Lab task flow for:
# 1) creating an NCC hub
# 2) creating NCC spokes for VPC1 and VPC2
# 3) verifying connectivity
# 4) setting up Private Service Connect (PSC)
# 5) connecting to Cloud SQL via the private DNS endpoint
#
# Notes:
# - Set PROJECT_ID and REGION before running if needed.
# - This is intended for Google Cloud Shell / Cloud Lab environments.
# - Replace the variables below to match your lab environment.
# ==========================================================

PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo '')}"
REGION="${REGION:-$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-region])' 2>/dev/null || echo '')}"
ZONE="${ZONE:-$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-zone])' 2>/dev/null || echo '')}"
HUB_NAME="${HUB_NAME:-ncc-hub}"
VPC1_NAME="${VPC1_NAME:-vpc1-ncc}"
VPC2_NAME="${VPC2_NAME:-vpc2-ncc}"
PSC_IP="${PSC_IP:-10.0.0.10}"
SQL_INSTANCE_NAME="${SQL_INSTANCE_NAME:-}"

if [[ -z "$PROJECT_ID" ]]; then
  echo "PROJECT_ID is not set. Run: export PROJECT_ID=<your-project-id>"
  exit 1
fi

if [[ -z "$REGION" ]]; then
  echo "REGION is not set. Run: export REGION=<your-region>"
  exit 1
fi

if [[ -z "$ZONE" ]]; then
  echo "ZONE is not set. Run: export ZONE=<your-zone>"
  exit 1
fi

if [[ -z "$HUB_NAME" ]]; then
  echo "HUB_NAME is empty. Set: export HUB_NAME=<your-hub-name>"
  exit 1
fi

if [[ -z "$VPC1_NAME" ]]; then
  echo "VPC1_NAME is empty. Set: export VPC1_NAME=<your-vpc1-name>"
  exit 1
fi

if [[ -z "$VPC2_NAME" ]]; then
  echo "VPC2_NAME is empty. Set: export VPC2_NAME=<your-vpc2-name>"
  exit 1
fi

if [[ -n "$SQL_INSTANCE_NAME" ]]; then
  echo "Using SQL instance: $SQL_INSTANCE_NAME"
else
  echo "SQL_INSTANCE_NAME is not set. PSC / Cloud SQL steps will be skipped or require manual setup."
  echo "Set it with: export SQL_INSTANCE_NAME=<your-cloudsql-instance-name>"
fi

echo "========================================="
echo "Project: $PROJECT_ID"
echo "Region : $REGION"
echo "Zone   : $ZONE"
echo "========================================="

echo
# ==========================================================
# Task 1: Create the NCC hub
# ==========================================================

echo "[Task 1] Creating NCC hub: $HUB_NAME"
if gcloud network-connectivity hubs describe "$HUB_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Hub $HUB_NAME already exists; skipping creation."
else
  gcloud network-connectivity hubs create "$HUB_NAME" \
    --project="$PROJECT_ID" \
    --description="NCC Hub for VPC connectivity"
fi

gcloud network-connectivity hubs describe "$HUB_NAME" --project="$PROJECT_ID"

echo
# ==========================================================
# Task 2: Configure VPCs as NCC spokes
# ==========================================================

echo "[Task 2] Listing subnets for VPC1"
gcloud config set accessibility/screen_reader false

gcloud compute networks subnets list --network="$VPC1_NAME" --project="$PROJECT_ID"

echo

echo "[Task 2] Configure VPC1 as NCC spoke and exclude 10.1.2.0/24 export route"
gcloud network-connectivity spokes linked-vpc-network create vpc1-spoke1 \
  --project="$PROJECT_ID" \
  --hub="$HUB_NAME" \
  --vpc-network="$VPC1_NAME" \
  --exclude-export-ranges=10.1.2.0/24 \
  --global || echo "vpc1-spoke1 may already exist; continuing..."

echo

echo "[Task 2] Configure VPC2 as NCC spoke and exclude 10.3.3.0/24 export route"
gcloud network-connectivity spokes linked-vpc-network create vpc2-spoke2 \
  --project="$PROJECT_ID" \
  --hub="$HUB_NAME" \
  --vpc-network="$VPC2_NAME" \
  --exclude-export-ranges=10.3.3.0/24 \
  --global || echo "vpc2-spoke2 may already exist; continuing..."

echo

echo "[Task 2] List default route table entries in the hub"
gcloud network-connectivity hubs route-tables routes list \
  --hub="$HUB_NAME" \
  --route_table=default \
  --project="$PROJECT_ID"

echo
# ==========================================================
# Task 3: Verify IPv4 traffic path connectivity
# ==========================================================

echo "[Task 3] SSH to vm1-vpc1-ncc and run:"
echo "  sudo tcpdump -i any icmp -v -e -n"
echo

echo "Then SSH to vm2-vpc2-ncc and run:"
echo "  ping 10.1.1.2"
echo

echo "This validates the VPC to VPC ICMP path through NCC."

echo
# ==========================================================
# Task 4: Private Service Connect setup
# ==========================================================

echo "[Task 4] Discover the VPC2 subnet CIDR for the PSC endpoint"
SUBNET_CIDR=$(gcloud compute networks subnets describe "vpc2-ncc-subnet1" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --format='value(ipCidrRange)')

echo "Subnet CIDR: $SUBNET_CIDR"

echo

echo "Choose a free IP address inside the CIDR range above and set it in PSC_IP before continuing."
PSC_IP="${PSC_IP:-10.0.0.10}"
if [[ "$PSC_IP" == "10.0.0.10" ]]; then
  echo "Using demo PSC_IP=$PSC_IP. Replace this with a free IP inside vpc2-ncc-subnet1."
fi

gcloud compute addresses create cloudsql-psc \
  --project="$PROJECT_ID" \
  --region="$REGION" \
  --subnet="vpc2-ncc-subnet1" \
  --addresses="$PSC_IP" || echo "Address is in use or already exists; try another free IP in the same CIDR range."

gcloud compute addresses list --project="$PROJECT_ID" --filter="name=cloudsql-psc"

echo

echo "[Task 4] Get the PSC service attachment URI from the Cloud SQL instance"
SQL_INSTANCE_NAME="${SQL_INSTANCE_NAME:-}"
if [[ -z "$SQL_INSTANCE_NAME" ]]; then
  echo "Set SQL_INSTANCE_NAME to the Cloud SQL instance name before running the PSC endpoint creation step."
  echo "Example: export SQL_INSTANCE_NAME=my-cloudsql-instance"
else
  SERVICE_ATTACHMENT_URI=$(gcloud sql instances describe "$SQL_INSTANCE_NAME" \
    --project="$PROJECT_ID" \
    --format='value(pscServiceAttachmentLink)')

  echo "Service attachment URI: $SERVICE_ATTACHMENT_URI"

  gcloud compute forwarding-rules create cloudsql-psc-ep \
    --address=cloudsql-psc \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --network="$VPC2_NAME" \
    --target-service-attachment="$SERVICE_ATTACHMENT_URI" \
    --allow-psc-global-access

  gcloud compute forwarding-rules describe cloudsql-psc-ep \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --format='value(pscConnectionStatus)'
fi

echo
# ==========================================================
# Task 4: Create private DNS record for PSC
# ==========================================================

echo "[Task 4] Create a private DNS managed zone for Cloud SQL"
if gcloud dns managed-zones describe cloudsql-dns --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "DNS zone cloudsql-dns already exists; skipping creation."
else
  gcloud dns managed-zones create cloudsql-dns \
    --project="$PROJECT_ID" \
    --description="DNS zone for Cloud SQL via PSC" \
    --dns-name="${REGION}.sql.goog." \
    --networks="$VPC2_NAME" \
    --visibility=private
fi

if [[ -n "$SQL_INSTANCE_NAME" ]]; then
  DNS_RECORD=$(gcloud sql instances describe "$SQL_INSTANCE_NAME" --project="$PROJECT_ID" --format='value(dnsName)')
  echo "DNS record to add: $DNS_RECORD"

  gcloud dns record-sets create "$DNS_RECORD" \
    --project="$PROJECT_ID" \
    --type=A \
    --rrdatas="$PSC_IP" \
    --zone=cloudsql-dns
fi

echo
# ==========================================================
# Task 5: Connect to Cloud SQL via private service connect
# ==========================================================

echo "[Task 5] Connect to the cloudsql-client VM via IAP"
echo "Run this command from Cloud Shell:"
echo "  gcloud compute ssh --zone $ZONE \"cloudsql-client\" --tunnel-through-iap --project $PROJECT_ID"
echo

echo "Then connect to Postgres using:"
echo "  psql \"sslmode=disable dbname=postgres user=postgres host=[DNS_RECORD]\""
echo

echo "Example SQL commands:"
cat <<'EOF'
CREATE DATABASE company;
\l
\c company
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first VARCHAR(255) NOT NULL,
    last VARCHAR(255) NOT NULL,
    salary DECIMAL(10,2)
);
INSERT INTO employees (first, last, salary) VALUES
    ('Max', 'Mustermann', 5000.00),
    ('Anna', 'Schmidt', 7000.00),
    ('Peter', 'Mayer', 6000.00);
SELECT * FROM employees;
\q
EOF

echo
echo "======================================================="
echo " NCC LAB FLOW COMPLETED OR READY FOR MANUAL HANDOFF "
echo "======================================================="
