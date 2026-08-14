# Establish VPC to VPC Connectivity using NCC

Set your lab-specific values before running it:

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=us-east1
export ZONE=us-east1-c
export HUB_NAME=ncc-hub
export VPC1_NAME=vpc1-ncc
export VPC2_NAME=vpc2-ncc
export PSC_IP=10.2.2.10
export SQL_INSTANCE_NAME=cloudsql-postgres-ymiy
```

## Run the Script

```bash
curl -LO "https://raw.githubusercontent.com/cloudbypriyank/Google-A2026/main/Establish%20VPC%20to%20VPC%20Connectivity%20using%20NCC/span.sh"
chmod +x span.sh
./span.sh
```

## Verify the PSC Connection

After the script finishes, check the PSC connection status:

```bash
gcloud compute forwarding-rules describe cloudsql-psc-ep \
  --region=us-east1 \
  --format="value(pscConnectionStatus)"
```

The expected output is:

```text
ACCEPTED
```

## Get the Cloud SQL DNS Name

Run:

```bash
gcloud sql instances describe cloudsql-postgres-ymiy \
  --format="value(dnsName)"
```

Copy the DNS name returned by this command.

## Connect to the Cloud SQL Client VM

From Cloud Shell, run:

```bash
gcloud compute ssh cloudsql-client \
  --zone=us-east1-c \
  --tunnel-through-iap \
  --project="$PROJECT_ID"
```

If prompted for an SSH key passphrase, press **Enter** if the key was created without a passphrase.

## Connect to Cloud SQL Using PSC

Inside the `cloudsql-client` VM, run:

```bash
psql "sslmode=disable dbname=postgres user=postgres host=YOUR_DNS_NAME"
```

Replace `YOUR_DNS_NAME` with the DNS name returned by the previous command.

A successful connection should give you a PostgreSQL prompt similar to:

```text
postgres=#
```

> Do not run `psql` by itself. Running only `psql` attempts to connect to a PostgreSQL server running locally on the `cloudsql-client` VM.

## Create and Populate the Database

After connecting to PostgreSQL, run:

```sql
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

## Expected Result

The `SELECT` command should display the three inserted employees:

```text
 id | first |    last    | salary
----+-------+------------+--------
  1 | Max   | Mustermann | 5000.00
  2 | Anna  | Schmidt    | 7000.00
  3 | Peter | Mayer       | 6000.00
```

## Lab Values Used

| Variable            | Value                    |
| ------------------- | ------------------------ |
| Project ID          | Automatically detected   |
| Region              | `us-east1`               |
| Zone                | `us-east1-c`             |
| NCC Hub             | `ncc-hub`                |
| VPC 1               | `vpc1-ncc`               |
| VPC 2               | `vpc2-ncc`               |
| VPC2 Subnet         | `vpc2-ncc-subnet1`       |
| VPC2 Subnet CIDR    | `10.2.2.0/24`            |
| VPC2 VM IP          | `10.2.2.2`               |
| Cloud SQL Client IP | `10.2.2.3`               |
| PSC IP              | `10.2.2.10`              |
| Cloud SQL Instance  | `cloudsql-postgres-ymiy` |

> **Note:** Lab resources can differ between environments. If you are sharing this script with other students, they may need to update the region, zone, PSC IP, or Cloud SQL instance name to match their own lab environment.
