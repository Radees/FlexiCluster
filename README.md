# FlexiCluster

A comprehensive Ansible infrastructure management system for Enterprise Package Management (EPM) environments, combining cluster management, virtualization, storage, and monitoring capabilities.

> **Repository**: `Radees/FlexiCluster` (formerly `epm-breadcrumbs`)
> **Note**: This repository is the result of merging `epm-breadcrumbs` and `e-space` repositories into a unified infrastructure automation platform.

## Overview

This repository provides complete infrastructure automation for Linux clusters with:
- **High Availability**: Pacemaker/Corosync cluster management
- **Storage Replication**: DRBD and Linstor configurations
- **Virtualization**: KVM/libvirt VM management
- **Identity Management**: OneIdentity/SSSD integration
- **Monitoring**: Zabbix agent setup
- **Network Management**: Bond, VLAN, and bridge configurations

## Quick Start

```bash
cd ansible/

# Run server audit
ansible-playbook playbooks/server_audit.yaml

# Find VM host across cluster
ansible-playbook playbooks/vm_finder.yaml -e "vm_name=myvm"

# Configure PCM/Pacemaker resources
ansible-playbook playbooks/pcm_resources.yaml
```

👉 **[See Ansible README](ansible/README.md)** for complete documentation

## Repository Structure

```
FlexiCluster/
├── ansible/                        # Main Ansible infrastructure
│   ├── playbooks/                  # Playbooks for various operations
│   ├── roles/                      # Reusable Ansible roles
│   │   ├── cluster_base/          # Base cluster configuration
│   │   ├── cluster_drbd/          # DRBD storage replication
│   │   ├── cluster_pacemaker/     # Pacemaker HA cluster
│   │   ├── cluster_linstor/       # Linstor storage management
│   │   ├── cluster_vm/            # Virtual machine management
│   │   ├── cluster_monitoring/    # Monitoring setup (Zabbix)
│   │   ├── cluster_identity/      # Identity management
│   │   ├── cluster_network/       # Network configuration
│   │   └── ubuntu_packages/       # Package installation
│   ├── inventory/                  # Production & staging inventories
│   ├── inventories/                # Alternative inventory structure
│   ├── files/                      # Configuration files and scripts
│   ├── templates/                  # Jinja2 templates
│   └── docs/                       # Cluster documentation
│       ├── SELI cluster/          # SELI cluster documentation
│       └── SERO cluster/          # SERO cluster documentation
├── docs/                           # General documentation
│   ├── guides/                     # How-to guides and references
│   └── archive/                    # Archived legacy files
├── README.md                       # This file
├── CONTRIBUTING.md                 # Contribution guidelines
└── LICENSE                         # License information
```

## Key Features

### 🎯 Infrastructure Management

**Server Auditing**
- Network configuration and connectivity checks
- NTP/time synchronization verification
- DNS configuration and resolution testing
- Authentication system checks (SSSD, LDAP, OneIdentity)
- User and group membership validation
- System resource monitoring

**Cluster Management**
- Pacemaker/Corosync cluster setup and configuration
- Floating IP and resource management
- Resource group constraints and preferences
- Cluster health monitoring and status checks

**Storage Management**
- DRBD storage replication setup
- Linstor distributed storage configuration
- Storage pool management
- Volume creation and management
- LVM integration

**Virtualization**
- KVM/libvirt virtual machine management
- VM discovery across cluster nodes
- VM migration and failover
- Resource allocation and management
- CDROM and device management

**Network Configuration**
- Network bond configuration
- VLAN setup and management
- Bridge creation for virtual networks
- Network interface management

**Monitoring & Identity**
- Zabbix agent installation and configuration
- OneIdentity vastool integration
- Kerberos authentication setup
- SSSD configuration for LDAP/AD

### 📋 Available Playbooks

| Playbook | Purpose |
|----------|---------|
| `server_audit.yaml` | Comprehensive server configuration audit |
| `vm_finder.yaml` | Locate VMs across cluster nodes |
| `vm_discovery_playbook.yaml` | Discover and inventory all VMs |
| `vm_management.yaml` | VM lifecycle management |
| `vm_cdrom_eject.yaml` | Manage VM CD-ROM devices |
| `vm_drbd_pcm.yaml` | Integrate VMs with DRBD and Pacemaker |
| `pcm_resources.yaml` | Configure Pacemaker cluster resources |
| `oneidentity_linbit_check.yaml` | Check OneIdentity and LINBIT storage |
| `cluster_setup.yaml` | Complete cluster setup orchestration |

### 🔧 Cluster Roles

All cluster management roles follow a consistent structure with:
- Pre-installation checks
- Package installation
- Service configuration
- Health verification

See [ansible/README.md](ansible/README.md) for detailed role documentation.

## Documentation

- **[Ansible README](ansible/README.md)** - Complete Ansible documentation
- **[Contributing Guide](CONTRIBUTING.md)** - Coding standards and conventions
- **[Cluster Documentation](ansible/docs/)** - Detailed cluster configurations
- **[Guides](docs/guides/)** - How-to guides and references

## Naming Conventions

This repository follows strict naming conventions for consistency:

- **Playbooks**: `snake_case.yaml` (e.g., `server_audit.yaml`)
- **Roles**: `snake_case` with `cluster_` prefix (e.g., `cluster_drbd`)
- **Variables**: `snake_case` (e.g., `floating_ip`)
- **Extensions**: Always use `.yaml` (NOT `.yml`)

See [CONTRIBUTING.md](CONTRIBUTING.md) for complete guidelines.

## Testing

### Syntax Check
```bash
ansible-playbook --syntax-check playbooks/server_audit.yaml
```

### Dry Run
```bash
ansible-playbook --check playbooks/server_audit.yaml
```

### Selective Execution with Tags
```bash
# Run only network checks
ansible-playbook playbooks/server_audit.yaml --tags network

# Run multiple tags
ansible-playbook playbooks/server_audit.yaml --tags network,ntp,dns
```

### Limit to Specific Hosts
```bash
ansible-playbook playbooks/server_audit.yaml -l node1
```

## Environment Management

The repository supports multiple environments:

```bash
# Production (default)
ansible-playbook playbooks/server_audit.yaml

# Staging
ansible-playbook -i inventory/staging/hosts.yaml playbooks/server_audit.yaml
```

## Architecture

**FlexiCluster** (`Radees/FlexiCluster`) is a unified infrastructure management system created by merging:
- **Original epm-breadcrumbs**: Core EPM scripts, testing tools, and documentation
- **e-space repository**: Comprehensive cluster management roles and configurations

The merged codebase provides an integrated platform for managing complex high-availability cluster environments with standardized conventions and best practices.

## Requirements

- **Ansible**: 2.9 or higher
- **Target Systems**: Ubuntu 18.04+ (Bionic or later)
- **Access**: SSH key-based authentication
- **Privileges**: sudo access on target systems

## Contributing

We welcome contributions! Please:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
2. Follow naming conventions and code standards
3. Test changes in staging environment
4. Submit pull requests with clear descriptions

## Archived Content

Legacy files have been moved to `docs/archive/`:
- `docs/archive/original-txt-files/` - Original .txt playbook drafts
- `docs/archive/shell-scripts/` - Standalone test scripts

## Support

- **Ansible Issues**: Check [ansible/README.md](ansible/README.md)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **General Questions**: Open an issue with details

## License

See [LICENSE](LICENSE) file for license information.

---

**Note**: This repository follows Ansible best practices including:
- Fully Qualified Collection Names (FQCNs)
- Comprehensive error handling
- Idempotent operations
- Tag-based selective execution
- Proper role structure and organization
