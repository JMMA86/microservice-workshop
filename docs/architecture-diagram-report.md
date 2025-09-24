# Microservices Application Architecture

This document describes the architecture proposed in the diagram included in this repository.
The current implementation is not multi-region, but the design was mapped this way to show the ideal configuration in terms of resilience and availability.

## Overview

The solution is built on Azure Kubernetes Service (AKS) and uses a set of Azure services to ensure scalability, resilience, and continuous deployments.

The objective is to show how a highly available architecture could be implemented by distributing resources across two Azure regions.

## Architecture Flow

1. **Traffic Ingress (Front Door)**
    - Traffic from the Internet enters through the Azure Front Door.
    - The Front Door performs global load balancing and routes requests to the available regions.
    - If one region fails, traffic is automatically redirected to the other.

2. **Regional Load Balancers**
    - Each region has a **Regional Load Balancer**, which distributes incoming traffic within its respective Kubernetes cluster.
    - These load balancers work together with the **Ingress Controller** to expose application services.

3. **Kubernetes Cluster on AKS**
    - Each region has an **AKS cluster** with the following components deployed:
        - **Frontend**: Main application interface.
        - **Auth REST API**: Manages user authentication.
        - **Users REST API**: Exposes user-related endpoints.
        - **TODOs REST API**: Exposes endpoints for CRUD task operations.
        - **Log Processor**: Service responsible for consuming and processing logs asynchronously.
        - **Azure Cache for Redis (geo-replicated)**: In-memory database used to store data and manage log queues.
    > The design shows **asynchronous geo-replication** to ensure availability in both regions.

4. **CI/CD and Container Images**
    - **Azure Pipelines** is used for continuous integration and deployment (CI/CD).
    - The generated images are stored in the **Azure Container Registry (ACR)**.
    - AKS clusters in both regions pull images from ACR to deploy applications.
    - **Kustomize** is used to manage deployment configurations.

5. **Cross-Region Connectivity**
    - Clusters and resources in both regions are connected via **VNET Peering**.
    - This enables data replication and secure communication between regions.

## High Availability and Disaster Recovery

- **Front Door** ensures that if one entire region goes down, traffic continues to flow to the other region.
- **Azure Cache for Redis (geo-replicated)** ensures data is available in both regions.
- **Centralized CI/CD and global ACR** simplify administration and avoid duplicating resources.

## Design Benefits

- **Scalability**: Kubernetes allows for dynamic resource adjustment.
- **Resilience**: Multi-region deployment with automatic failover.
- **Decoupling**: Independent APIs with synchronous and asynchronous communication.
- **Continuous lifecycle**: Continuous integration and deployment with automated pipelines.
- **Data availability**: Geo-replicated Redis ensures eventual consistency and low latency in both regions.