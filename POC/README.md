# ✈️ Real-Time India Flight Telemetry Platform

> End-to-End Cloud-Native Data Engineering Pipeline for Real-Time Aviation Analytics

![Architecture](https://img.shields.io/badge/Architecture-Medallion-blue)
![AWS](https://img.shields.io/badge/AWS-Serverless-orange)
![Snowflake](https://img.shields.io/badge/Snowflake-Data%20Warehouse-blue)
![dbt](https://img.shields.io/badge/dbt-Transformation-orange)
![Tableau](https://img.shields.io/badge/Tableau-Visualization-blue)

---

For Detailed View Visit: https://mihir-poc.lovable.app/

---

# 📌 Project Overview

Indian airspace handles thousands of aircraft movements every day across domestic and international routes.

This project demonstrates how a modern cloud-native data engineering stack can ingest live ADS-B aircraft telemetry, process it through a Medallion Architecture (Bronze → Silver → Gold), and serve real-time operational dashboards.

The solution is fully automated, event-driven, scalable, and designed using modern data engineering best practices.

---

# 🎯 Objectives

The primary objectives of this POC are:

* Ingest live aircraft telemetry in near real-time
* Build a serverless event-driven data pipeline
* Implement Medallion Architecture
* Load data continuously into Snowflake
* Create business-ready Gold layer models using dbt
* Deliver real-time Tableau dashboards
* Demonstrate cloud-native data engineering practices
* Minimize operational and infrastructure costs

---

# 🏗️ High-Level Architecture

```text
                    AIRPLANES.LIVE API
                           │
                           ▼
                  EventBridge (1 min)
                           │
                           ▼
                 Lambda: Poll Flight Data
                           │
                           ▼
                     S3 Bronze (JSON)
                           │
                           ▼
                 S3 Event Notification
                           │
                           ▼
                          SQS
                           │
                           ▼
              Lambda: Transform to Parquet
                           │
                           ▼
                     S3 Silver Layer
                           │
                           ▼
                       Snowpipe
                           │
                           ▼
              Snowflake STAGING Layer
                           │
                           ▼
                      dbt Cloud
                           │
                           ▼
                Snowflake GOLD Layer
                           │
                           ▼
                    Tableau Desktop
```

---

# 🔄 End-to-End Data Flow

## Step 1 – Data Collection

Live flight telemetry is collected from Airplanes.live.

### Coverage Strategy

The API supports a maximum radius of 250 nautical miles.

To achieve full India coverage, seven polling locations are used:

| Region    | Latitude | Longitude |
| --------- | -------- | --------- |
| Delhi     | 28.6139  | 77.2090   |
| Mumbai    | 19.0760  | 72.8777   |
| Chennai   | 13.0827  | 80.2707   |
| Bangalore | 12.9716  | 77.5946   |
| Kolkata   | 22.5726  | 88.3639   |
| Ahmedabad | 23.0225  | 72.5714   |
| Hyderabad | 17.3850  | 78.4867   |

The poller performs:

* 7 parallel API requests
* Aircraft deduplication using ICAO24 (hex)
* Snapshot generation every minute

Result:

~500+ aircraft per snapshot

---

## Step 2 – Bronze Layer

### Storage

AWS S3

Bucket:

```text
raw-flight-data-mm
```

### Format

```text
JSON
```

### Purpose

Store raw immutable telemetry data.

Example:

```text
year=2026/
month=06/
day=25/
flight_data_20260625_120001.json
```

---

## Step 3 – Event-Driven Processing

Whenever a JSON file lands in Bronze:

```text
S3 Event
    ↓
SQS Queue
    ↓
Transformer Lambda
```

Benefits:

* Loose coupling
* Fault tolerance
* Retry capability
* Event-driven processing

---

## Step 4 – Silver Layer

### Storage

```text
flight-silver-bucket-mm
```

### Format

```text
Apache Parquet
```

### Transformation Logic

Raw aircraft records are flattened and cleaned.

### Data Quality Handling

Example:

```python
"alt_baro": "ground"
```

is converted into a valid numeric value before processing.

### Derived Attributes

| Derived Column | Purpose                       |
| -------------- | ----------------------------- |
| flight_phase   | Ground / Climb / Cruise       |
| vertical_trend | Climbing / Descending / Level |
| speed_category | Aircraft speed bucket         |
| grid_cell      | Airspace density analysis     |
| is_heavy       | Wide-body aircraft detection  |

Result:

Business-ready Parquet files.

---

# ❄️ Snowflake Layer

## Components

### Storage Integration

Secure AWS-Snowflake connectivity.

### External Stage

References Silver bucket.

### Snowpipe

Provides continuous auto-ingestion.

### Staging Table

```text
FLIGHT_DB.STAGING.STG_FLIGHTS
```

### Characteristics

* 44 columns
* Auto-ingest
* Near real-time loading
* Event-driven

---

# 🥇 Gold Layer (dbt Cloud)

The Gold layer contains business-ready analytical models.

---

## 1. dim_aircraft

Dynamic aircraft reference table.

Purpose:

* Aircraft categorization
* Manufacturer enrichment
* Aircraft family mapping

Examples:

```text
A320 → Airbus
B738 → Boeing
E190 → Embraer
```

---

## 2. fct_flights

Primary fact table.

Contains:

* Flight telemetry
* Airport enrichment
* State enrichment
* Aircraft enrichment

Metrics:

* 62 columns
* Incremental model
* Unique key:
  hex + snapshot_ts

---

## 3. fct_airspace_density

Aggregated airspace statistics.

Grain:

```text
Grid Cell
Per Minute
Flight Phase
```

Used for:

* Airspace heatmaps
* Congestion analysis
* Traffic density monitoring

---

## 4. fct_rolling_stats

Window-function based analytics.

Examples:

* Rolling average altitude
* Rolling average speed
* Session max altitude
* Aircraft ranking

---

# 🧱 Medallion Architecture

```text
BRONZE
│
├── Raw JSON
├── Immutable
└── Historical Storage

        ↓

SILVER
│
├── Cleaned
├── Typed
├── Derived Columns
└── Parquet

        ↓

GOLD
│
├── Business Logic
├── Dimensions
├── Fact Tables
└── Analytics Ready
```

---

# 📊 Data Model

## Dimensions

### dim_aircraft

Aircraft reference model.

### dim_airports

~320 Indian airports.

Source:

OurAirports

### dim_regions

Indian state boundaries.

---

## Facts

### fct_flights

Aircraft level grain.

### fct_airspace_density

Grid level grain.

### fct_rolling_stats

Aircraft trend grain.

---

# 🔍 Data Quality Practices

Implemented throughout the pipeline.

### Validation

* NOT NULL tests
* Accepted values tests
* Referential integrity

### dbt Tests

Examples:

```yaml
hex:
  tests:
    - not_null

snapshot_ts:
  tests:
    - not_null
```

### Edge Cases Handled

* Missing coordinates
* Missing aircraft type
* Invalid altitude values
* Ground aircraft altitude strings

---

# ⚙️ Engineering Best Practices

## Event-Driven Architecture

No polling between services.

Everything reacts to events.

```text
S3
 ↓
SQS
 ↓
Lambda
 ↓
Snowpipe
```

---

## Incremental Processing

Only new data is processed.

Benefits:

* Faster execution
* Lower cost
* Better scalability

---

## Dynamic Dimensions

Aircraft reference data is automatically generated from live traffic.

No manual maintenance required.

---

## Partitioned Storage

Both Bronze and Silver layers use:

```text
year=
month=
day=
```

partitioning.

Benefits:

* Faster retrieval
* Lower storage scan costs

---

## Infrastructure Cost Optimization

Glue was originally considered.

Decision:

```text
Glue ❌
Lambda ✅
```

Savings:

Approximately $50/week.

---

# ☁️ AWS Services Used

| Service     | Purpose                    |
| ----------- | -------------------------- |
| EventBridge | Scheduler                  |
| Lambda      | Ingestion & Transformation |
| S3          | Data Lake                  |
| SQS         | Event Messaging            |
| CloudWatch  | Monitoring                 |
| SNS         | Alerts                     |

---

# ❄️ Snowflake Components

| Component           | Purpose         |
| ------------------- | --------------- |
| Storage Integration | AWS Access      |
| External Stage      | S3 Reference    |
| Snowpipe            | Continuous Load |
| STG_FLIGHTS         | Landing Table   |

---

# 🔥 dbt Features Used

* Incremental Models
* Sources
* Schema Tests
* Documentation
* Lineage
* Model Dependencies
* Scheduled Jobs

Production Schedule:

```text
*/5 * * * *
```

---

# 📈 Tableau Dashboards

## Dashboard 1

### Real-Time India Flight Telemetry

Features:

* Live Flight Map
* Airspace Density
* KPI Cards
* Flight Phase Distribution
* Top Airlines

---

## Dashboard 2

### India Airspace Operations Center

Features:

* Emergency Monitoring
* Airport Activity
* Traffic Analysis
* Altitude Bands
* Domestic vs International Split

---

# 📂 Repository Structure

```text
Poc_DBT
│
├── dbt_project.yml
├── packages.yml
│
├── models
│   ├── sources.yml
│   ├── schema.yml
│   │
│   └── gold
│       ├── dim_aircraft.sql
│       ├── fct_flights.sql
│       ├── fct_airspace_density.sql
│       └── fct_rolling_stats.sql
│
├── tests
│
└── seeds
```

---

# 📊 Sample Metrics

Current observations from live telemetry:

* 500+ aircraft per snapshot
* 83% aircraft cruising
* 156 heavy aircraft observed
* Delhi busiest airspace region
* 511 domestic flights
* 228 international flights

---

# 💰 Cost Analysis

| Service         | Cost      |
| --------------- | --------- |
| S3              | Free Tier |
| Lambda          | Free Tier |
| EventBridge     | Free Tier |
| SQS             | Free Tier |
| CloudWatch      | Free Tier |
| Snowflake Trial | $0        |
| Snowpipe        | Minimal   |

Estimated Total:

```text
~$0 during POC execution
```

---

# 🚀 Key Learnings

* Building event-driven architectures
* Real-time streaming patterns
* Serverless data engineering
* Medallion architecture implementation
* Snowflake auto-ingestion with Snowpipe
* Incremental modeling using dbt
* Operational analytics design
* Cost optimization strategies

---

# 👨‍💻 Author

Mihir Mungara

Simform

Data Engineering Internship Project

---

# ⭐ Future Enhancements

* Apache Airflow orchestration
* Real-time streaming with Kafka
* Historical trend dashboards
* Flight route reconstruction
* Predictive congestion analytics
* ML-based delay prediction
* Real-time anomaly detection

---

## Final Outcome

A complete cloud-native data engineering platform that transforms live aircraft telemetry into business-ready analytics within minutes using AWS, Snowflake, dbt, and Tableau.
