# Establish VPC to VPC Connectivity using NCC


Set your lab-specific values before running it:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-region])')
export ZONE=$(gcloud compute project-info describe --format='value(commonInstanceMetadata.items[google-compute-default-zone])')
export HUB_NAME=ncc-hub
export VPC1_NAME=vpc1-ncc
export VPC2_NAME=vpc2-ncc
export PSC_IP=10.0.0.10
export SQL_INSTANCE_NAME=your-cloudsql-instance-name
```

Run the script:

```bash
curl -LO https://raw.githubusercontent.com/cloudbypriyank/Google-A2026/main/Establish%20VPC%20to%20VPC%20Connectivity%20using%20NCC/span.sh
chmod +x span.sh
./span.sh
```

```bash
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
```
> Replace the values above if your lab uses different VPC names, subnet ranges, or Cloud SQL instance names.
