curl -LO https://raw.githubusercontent.com/cloudbypriyank/Google-A2026/main/Establish%20VPC%20to%20VPC%20Connectivity%20using%20NCC/span.sh
sudo chmod +x span.sh

# Set your lab-specific values before running the script
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-region])')
export ZONE=$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-zone])')
export HUB_NAME=ncc-hub
export VPC1_NAME=vpc1-ncc
export VPC2_NAME=vpc2-ncc
export PSC_IP=10.0.0.10
export SQL_INSTANCE_NAME=your-cloudsql-instance-name

./span.sh
