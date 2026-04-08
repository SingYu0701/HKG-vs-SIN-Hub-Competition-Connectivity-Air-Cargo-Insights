# HKG vs SIN – Hub Competition, Connectivity & Air Cargo Insights
**Personal Data Analysis Project, Apr 2026** 
![Made with R](https://img.shields.io/badge/Made%20with-R-276DC3?logo=r&logoColor=white)

## Key Insights

- **HKG** has **broader global connectivity, especially long-haul routes**
- **SIN** shows higher entropy →  **more balanced route distribution**
- Airline networks follow strong Pareto concentration **(top routes dominate traffic)**
- **Air connectivity is positively correlated with air freight volume (economic proxy)**

Airline networks are critical infrastructure for:

- **Global trade (air freight)**
- **Economic connectivity**
- **Regional hub competition**

This project demonstrates how network science can be applied to real-world transportation systems.

## 1. Project Overview

This project analyzes the global airline network with a focus on two major aviation hubs:

- Hong Kong International Airport (HKG)
- Singapore Changi Airport (SIN)

The goal is to understand:

- Network structure and connectivity
- Route distribution patterns
- Hub centrality and importance
- Regional traffic concentration

This study combines:

- Airline route data
- Airport metadata
- Network graph analysis
- World Bank aviation freight indicators
  
## 2. Data Sources
### 2.1 OpenFlights Dataset
- `airports.dat`
- `routes.dat`

Used to construct the global airline network:

- Nodes: airports
- Edges: flight routes
- Edge weights: number of flights / airlines operating
  
### 2.2 World Bank Data

Indicator used:

- Air transport, freight (million ton-km)

This represents the total volume of goods transported via air freight at the country level.

## 3. Data Processing
### 3.1 Airport and Route Cleaning

Steps:

- Removed header inconsistencies
- Standardized column names
- Filtered valid airport and route records
- Mapped airport IDs to country and geographic information

### 3.2 Network Construction

A directed weighted graph was constructed:

- Nodes = airports
- Edges = routes between airports
- Weights = number of flights / route frequency

Network metrics computed:

- **Degree centrality**
- **Betweenness centrality**
- **Network density**
- **Transitivity (clustering tendency)**
  
## 4. Hong Kong (HKG) Route Analysis
### 4.1 Route Filtering

All routes associated with HKG were extracted:

- Outbound routes (HKG → X)
- Inbound routes (X → HKG)

### 4.2 Destination Distribution

Routes were aggregated at the country level to analyze destination concentration.

Key insights:

- **High concentration in East and Southeast Asia**
- **Strong regional connectivity**
- **High proportion of long-haul destinations compared to regional routes**
  
<img width="1606" height="941" alt="圖片" src="https://github.com/user-attachments/assets/97157c13-0111-47cb-9b56-2c6d4fcdea6c" />


### 4.3 Regional Breakdown

Countries were grouped into regions:

- East Asia
- Southeast Asia
- Other regions

**This highlights Hong Kong’s role as a asia regional hub also a globally dispersed hub.**
<img width="1449" height="1002" alt="圖片" src="https://github.com/user-attachments/assets/dd57ef4f-6704-42d8-855f-48155f26dbf3" />

## 5. Singapore (SIN) vs Hong Kong (HKG) Comparison
### 5.1 Route Distribution Comparison

Both hubs were compared in terms of:

- Number of destinations
- Country-level route distribution
- Traffic concentration

<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/d2f45b67-c50e-44b3-b72f-0fce7d1d004c" />


Observations:

- **HKG shows a more globally diversified network**
- **SIN is more regionally concentrated**
- **HKG tends to have broader long-haul connectivity**

<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/4737f45d-80e9-4cde-a991-c83000b71312" />
<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/acc1d796-c97c-4c0d-81af-c3a399285f79" />

### 5.2 Network Statistics Comparison

Metrics compared:

- Entropy (diversity of routes)
- Top-3 route share (concentration)
- Network density

<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/6555c725-9f96-4f74-8c60-ad0befaa1d2a" />


Interpretation:

- **Higher entropy → more diversified network**
- **Higher top-3 share → more concentrated traffic**
- **Density reflects overall connectivity of the hub**

Although Hong Kong appears to have a more visually diverse route map, Singapore exhibits higher entropy due to a more balanced distribution of traffic across routes, whereas Hong Kong’s traffic is more concentrated on a subset of high-volume connections.

## 6. Network Structure Analysis
### 6.1 Centrality Metrics

Two key centrality measures were computed:

- **Degree Centrality → number of direct connections**
- **Betweenness Centrality → importance as a transfer hub**
  
<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/f3b67462-7db1-4373-9550-de2b6d3cbbdc" />
<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/5f0331f7-645e-43dc-a0de-12297d6c8b09" />
<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/2db2ebb0-73af-4766-95b7-6f66589cd25a" />


Insights:

- **Major hubs exhibit both high degree and high betweenness**
- **Some airports act as transfer bridges despite moderate degree**

## 7. Subnetwork Analysis (Hong Kong)

A subnetwork of the top routes from HKG was extracted (e.g., top 15 destinations by traffic).

<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/b8be374d-03a9-415e-bfbd-c7fa91ff59ed" />


Purpose:

- Visualize the core structure of HKG’s connectivity
- Highlight dominant route flows
  
## 8. Geographic Visualization Regional Map (Asia Focus)

Filtered visualization focusing on Asia:

Highlights regional dominance of HKG routes
Removes global noise for clarity

<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/de1bffc7-bd1f-4f08-b379-698c5351a04c" />


## 9. Network Concentration Analysis

Route traffic distribution was analyzed using cumulative share:

- Routes ranked by traffic volume
- Cumulative percentage computed

Key concept: Pareto principle (80/20 rule)
<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/59c4fa2d-5cb6-4c00-9795-9703d585307d" />

Finding:

**A small fraction of routes accounts for a large proportion of total traffic**

## 10. World Bank Integration Analysis
### 10.1 Data Alignment

Merged:

- Airline network metrics (country-level aggregation)
- World Bank air freight data
  
### 10.2 Relationship Between Connectivity and Freight

A cross-sectional analysis was conducted:

X-axis: Total flight connectivity (network proxy)

Y-axis: Air freight volume (economic activity proxy)

<img width="2560" height="1317" alt="圖片" src="https://github.com/user-attachments/assets/37e9ff64-209e-44c7-b79d-162b65917da3" />


### 10.3 Correlation Analysis

Computed correlation between:

- Network connectivity
- Air freight volume

Interpretation:

Positive correlation suggests that:
- Countries with **stronger air connectivity tend to have higher air cargo volumes**
- Airline network structure reflects **underlying economic activity**

## 11. Key Findings
- **Hong Kong** demonstrates a more **globally diversified network, with stronger long-haul connectivity.**
- **Singapore** exhibits a **regionally concentrated hub structure, primarily focused on Southeast Asia.**
- Airline networks follow a **highly skewed distribution, where a small number of routes dominate total traffic.**
- Network centrality measures **effectively identify major aviation hubs and transfer nodes.**
- Integration with World Bank data shows a **positive relationship between air connectivity and freight volume**, indicating **economic relevance** of network structure.

## 12. Skills Demonstrated

This project demonstrates:

- Network analysis (igraph)
- Data cleaning and transformation (R / tidyverse)
- Graph metrics (centrality, density, entropy)
- Data visualization (ggplot2, network plots)
- Geographic visualization
- Cross-dataset integration (World Bank API)
- Statistical reasoning and interpretation
