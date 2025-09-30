# My Homelab Project

# Enterprise Kubernetes Homelab

![Kubernetes](https://img.shields.io/badge/kubernetes-v1.31-blue)
![Proxmox](https://img.shields.io/badge/proxmox-8.x-orange)
![Rocky Linux](https://img.shields.io/badge/rocky%20linux-9.x-green)
![License](https://img.shields.io/badge/license-MIT-blue)

A production-grade Kubernetes homelab built on bare metal, implementing enterprise infrastructure patterns and best practices.

## Project Overview

This project documents the complete setup of an enterprise-grade Kubernetes cluster on bare metal infrastructure, designed to mirror real-world production environments. The goal is to create a learning platform that provides hands-on experience with technologies and patterns used in Fortune 500 companies.

### Key Features

- **High Availability**: 3-node control plane with etcd clustering
- **Infrastructure as Code**: Terraform for provisioning, Ansible for configuration
- **Enterprise Security**: SELinux enforcing, Network Policies, Pod Security Standards
- **Distributed Storage**: Longhorn for persistent volume management
- **Observability**: Prometheus, Grafana, and Loki stack
- **GitOps**: ArgoCD for declarative deployments
- **Production Patterns**: Load balancing, ingress, service mesh ready

## Architecture

### Infrastructure Stack
