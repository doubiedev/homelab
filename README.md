# Homelab

> Personal homelab infrastructure designed, deployed, and maintained as both a passion project and a practical environment for developing systems administration, networking, cybersecurity, and troubleshooting skills.

<!-- toc -->

- [About this Project](#about-this-project)
- [Overview](#overview)
- [Infrastructure](#infrastructure)
- [Networking](#networking)
- [Container Platform](#container-platform)
- [Reverse Proxy & TLS](#reverse-proxy--tls)
- [Authentication](#authentication)
- [Security](#security)
- [Operations & Troubleshooting](#operations--troubleshooting)
- [Documentation](#documentation)
- [Skills Demonstrated](#skills-demonstrated)
    * [Systems Administration](#systems-administration)
    * [Infrastructure](#infrastructure-1)
    * [Networking & Security](#networking--security)
    * [Operational Practices](#operational-practices)
- [Project Philosophy](#project-philosophy)

<!-- tocstop -->

## About this Project
<!-- TODO: adjust this section -->

My initial intention was simple to begin with - I wanted a way to watch downloaded content across different home devices without having to go through the mildly annoying process of copying to a USB. The solution? A home media server. Couldn't be that hard right?

At the time being enrolled in a Cybersecurity course at RMIT, I was enjoying the hands-on learning, particularly regarding networking, security, systems administration. As my interest and experience grew in these subjects, so too did the scope of the project. While there were many difficult concepts and frustrating problems I came across along the way, I derive great satisfaction from the learning process, and am grateful for the opportunity to present the result of my hard work and dedication (as much of a work in progress it still is).

What started as a single ubuntu server is now a clustered multi-node environment - combining virtualisation, Linux administration, containerised services, internal DNS, reverse proxying, authentication, VPN-based remote access, and service management across multiple hosts.

The repository serves as the configuration source for the environment and documents the architecture, operational decisions, and troubleshooting work involved in project development and maintenance.

## Overview

The homelab is built around a small Proxmox virtualisation environment hosting two Linux server VMs. These VMs form a Docker Swarm cluster used to run and manage containerised services.

The environment also includes a separate VPS used as an internet-facing entry point and secure connection point to the home network.

Below is a basic high-level diagram of the homelab architecture:
<!-- FIX: CHANGE DIAGRAM: should be diagram image linked from `diagrams/` -->
```text
                              Internet
                                  │
                                  ▼
                         ┌─────────────────┐
                         │   Cloudflare    │
                         │   doubie.dev    │
                         │  DNS / ACME DNS │
                         └────────┬────────┘
                                  │
                                  ▼
                         ┌─────────────────┐
                         │       VPS       │
                         │                 │
                         │     Traefik     │
                         │     NetBird     │
                         └────────┬────────┘
                                  │
                          NetBird VPN Tunnel
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                              Home Network                                │
│                                                                          │
│  ┌─────────────────────── Proxmox Cluster ────────────────────────────┐  │
│  │                                                                    │  │
│  │   ┌────────────┐           ┌────────────┐        ┌────────────┐    │  │
│  │   │   pve-1    │           │   pve-2    │        │   pve-3    │    │  │
│  │   │  Proxmox   │           │  Proxmox   │        │  Proxmox   │    │  │
│  │   └─────┬──────┘           └──────────┬─┘        └─────┬──────┘    │  │
│  │         │                             │                │           │  │
│  │         │                             │                │           │  │
│  │         │                             │                │           │  │
│  │   ┌─────┼────────────── Docker Swarm ─┼────────────────┼────────┐  │  │
│  │   │     ▼                             ▼                ▼        │  │  │
│  │   │  ┌────────────┐        ┌────────────┐        ┌────────────┐ │  │  │
│  │   │  │   srv-1    │        │   srv-2    │        │   srv-3    │ │  │  │
│  │   │  │     VM     │        │     VM     │        │     VM     │ │  │  │
│  │   │  │            │        │            │        │            │ │  │  │
│  │   │  │   Swarm    │        │   Swarm    │        │   Swarm    │ │  │  │
│  │   │  │   Manager  │        │   Worker   │        │   Worker   │ │  │  │
│  │   │  └─────┬──────┘        └─────┬──────┘        └─────┬──────┘ │  │  │
│  │   │        │                     │                     │        │  │  │
│  │   └────────┼─────────────────────┼─────────────────────┼────────┘  │  │
│  └────────────┼─────────────────────┼─────────────────────┼───────────┘  │
│               │                     │                     │              │
│               └─────────────────────┼─────────────────────┘              │
│                                     │                                    │
│                                     ▼                                    │
│                        ┌─────────────────────────┐                       │
│                        │        Services         │                       │
│                        │                         │                       │
│                        │  Traefik · Authentik    │                       │
│                        │  BIND9 · Applications   │                       │
│                        └─────────────────────────┘                       │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Infrastructure

| Component    | Role                                                |
| ------------ | --------------------------------------------------- |
| Proxmox      | Virtualisation platform                             |
| `pve-1, pve-2, pve-3`      | Proxmox host                                        |
| `srv-1`      | Docker Swarm manager                                |
| `srv-2, srv-3`      | Docker Swarm worker                                 |
| VPS          | Public entry point and remote-access infrastructure |
| Traefik      | Reverse proxy and TLS termination                   |
| Authentik    | Centralised authentication / SSO                    |
| BIND9        | Internal DNS                                        |
| NetBird      | Private network connectivity and remote access      |
| Docker Swarm | Container orchestration                             |
| Cloudflare   | Public DNS and ACME DNS challenge                   |

## Networking

The home network uses separate network ranges for the physical LAN, Proxmox hosts, and server VMs.

Key infrastructure networks include:

| Network          | Purpose                |
| ---------------- | ---------------------- |
| `192.168.0.0/16` | Home LAN               |
| `192.168.1.0/24` | Proxmox infrastructure |
| `192.168.2.0/24` | Server VMs             |
| `100.xx.0.0/24`  | NetBird VPN        |

Internal DNS is provided by BIND9, with external DNS handled through Cloudflare.

Internal clients can access services directly through the home network, while external access follows the VPS → NetBird → home infrastructure path.

See [Networking](docs/networking.md) and [DNS](docs/dns.md).

## Container Platform

Services are deployed using Docker Swarm.

The cluster consists of:

- `srv-1` — Swarm manager
- `srv-2` — Swarm worker
- `srv-3` — Swarm worker

Services are deployed from the `services/` directory using the `stackctl` management script.

```bash
./stackctl list
./stackctl start <stack>
./stackctl stop <stack>
./stackctl restart <stack>
./stackctl status <stack>
./stackctl ps <stack>
./stackctl logs <stack>
```

The script provides a consistent interface for deploying, removing, inspecting, and troubleshooting Swarm stacks.

See [Docker Swarm](docs/docker-swarm.md).

## Reverse Proxy & TLS

Traefik provides reverse proxying and TLS termination for services exposed through the environment.

The deployment uses Cloudflare DNS for ACME DNS challenges, allowing certificates to be issued without exposing certificate challenge endpoints directly to individual services.

Traffic is separated into internal and external paths:

<!-- TODO: Change these traffic flows to look better, maybe draw a couple diagrams -->
```text
Internal client
      │
      ▼
 Internal DNS
      │
      ▼
 Home Traefik
      │
      ▼
 Internal service
```

External access:

```text
Internet
    │
    ▼
Cloudflare
    │
    ▼
VPS Traefik
    │
    ▼
 NetBird
    │
    ▼
Home Traefik
    │
    ▼
Service
```

See [Reverse Proxy](docs/reverse-proxy.md) and [Remote Access](docs/remote-access.md).

## Authentication

Authentik provides centralised authentication for supported applications.

The goal is to avoid implementing authentication independently across every service while providing a consistent access-control layer.

Authentication is integrated with services through reverse-proxy and application-level authentication mechanisms where appropriate.

See [Authentication](docs/authentication.md).

## Security

Security is treated as part of the infrastructure design rather than as an additional layer added after deployment.

Key controls include:

- TLS for web services
- Centralised authentication and access management
- Private VPN connectivity through NetBird
- Limited public exposure
- Internal DNS
- Cloudflare DNS challenge for certificate issuance
- Docker secrets where supported
- Service placement within the Swarm cluster
- Separation between public-facing infrastructure and internal services
- Avoidance of unnecessary direct exposure of home services

Sensitive credentials, tokens, and environment-specific secrets are intentionally excluded from version control.

See [Security](docs/security.md).

## Operations & Troubleshooting

A significant purpose of the homelab is to practice systematic infrastructure troubleshooting.

Problems are investigated using a structured process:

1. Identify and reproduce the problem
2. Gather logs and system information
3. Isolate the affected component
4. Identify the underlying cause
5. Apply the smallest appropriate change
6. Verify the result
7. Document the solution and lessons learned

Examples include troubleshooting:

- Docker Swarm service placement
- Container filesystem permissions
- DNS resolution
- Reverse-proxy configuration
- TLS certificate issuance
- Authentication services
- Persistent application storage
- VPN routing
- Linux services and networking

See [Troubleshooting](docs/troubleshooting.md).

## Documentation

| Document                                     | Description                                      |
| -------------------------------------------- | ------------------------------------------------ |
| [Architecture](docs/architecture.md)         | Overall infrastructure architecture and design   |
| [Infrastructure](docs/infrastructure.md)     | Proxmox hosts, VMs, and server roles             |
| [Networking](docs/networking.md)             | Network topology, addressing, and routing        |
| [DNS](docs/dns.md)                           | BIND9, internal DNS, and public DNS              |
| [Remote Access](docs/remote-access.md)       | VPS, NetBird, and remote connectivity            |
| [Docker Swarm](docs/docker-swarm.md)         | Cluster architecture and service deployment      |
| [Reverse Proxy](docs/reverse-proxy.md)       | Traefik and TLS                                  |
| [Authentication](docs/authentication.md)     | Authentik and access control                     |
| [Security](docs/security.md)                 | Security controls and design decisions           |
| [Storage](docs/storage.md)                   | Persistent storage and filesystem considerations |
| [Backup & Recovery](docs/backup-recovery.md) | Backup strategy and recovery procedures          |
| [Troubleshooting](docs/troubleshooting.md)   | Real incidents and troubleshooting case studies  |

## Skills Demonstrated

This project provides practical experience across:

### Systems Administration

 Linux administration
 Service management
 Filesystem permissions
 Networking
 DNS
 Storage
 Virtualisation
 System troubleshooting

### Infrastructure

 Proxmox
 Docker
 Docker Swarm
 Reverse proxies
 TLS/ACME
 Virtual machines
 Persistent storage

### Networking & Security

 TCP/IP
 DNS
 Routing
 VPN
 Network segmentation
 Authentication
 Access control
 TLS
 Secrets management

### Operational Practices

 Infrastructure documentation
 Configuration management
 Troubleshooting
 Root-cause analysis
 Change management
 Service deployment
 Incident documentation

## Project Philosophy

The homelab is intentionally treated as an infrastructure environment rather than simply a collection of self-hosted applications.

Changes are documented, configurations are maintained in version control, services are deployed consistently, and failures are used as opportunities to investigate and understand the underlying systems.

The primary objective is to build practical experience that translates to real-world IT support, systems administration, networking, and infrastructure environments.
