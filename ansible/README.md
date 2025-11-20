# Ansible Infrastructure Management

This directory contains Ansible playbooks, roles, and configurations for managing EPM infrastructure, including cluster nodes, virtual machines, and storage systems.

> **Part of**: FlexiCluster (`Radees/FlexiCluster`) - A unified infrastructure management repository combining epm-breadcrumbs and e-space cluster management capabilities.

## Directory Structure

```
ansible/
├── ansible.cfg                          # Main Ansible configuration
├── inventory/                           # Inventory files
│   ├── production/                      # Production environment
│   │   ├── hosts.yaml                   # Production hosts inventory
│   │   ├── group_vars/
│   │   │   ├── all.yaml                 # Variables for all hosts
│   │   │   └── cluster_nodes.yaml       # Cluster-specific variables
│   │   └── host_vars/                   # Host-specific variables
│   └── staging/                         # Staging environment
│       ├── hosts.yaml                   # Staging hosts inventory
│       └── group_vars/
├── playbooks/                           # Ansible playbooks
│   ├── server_audit.yaml                # Comprehensive server audit
│   ├── vm_finder.yaml                   # Find VM host in cluster
│   ├── pcm_resources.yaml               # Configure PCM/Pacemaker resources
│   └── oneidentity_linbit_check.yaml    # Check vastool and LINBIT storage
├── roles/                               # Ansible roles
│   └── ubuntu_packages/                 # Package installation role
│       ├── defaults/
│       ├── files/
│       ├── handlers/
│       ├── meta/
│       ├── tasks/
│       ├── templates/
│       └── README.md
├── templates/                           # Jinja2 templates
│   ├── server_audit_report.j2           # Server audit report template
│   └── oneidentity_linbit_report.j2     # OneIdentity/LINBIT report template
└── docs/                                # Documentation
    ├── ansible-cheatsheet.md            # Ansible variables and commands reference
    └── ansible-package-role.md          # Package role documentation

```

## Quick Start

### Prerequisites

- Ansible 2.9 or higher
- SSH access to target hosts
- sudo privileges on target hosts
- SSH key configured (`~/.ssh/id_rsa` by default)

### Running Playbooks

Navigate to the ansible directory first:

```bash
cd ansible/
```

#### Server Audit

Run a comprehensive audit on all cluster nodes:

```bash
ansible-playbook playbooks/server_audit.yaml
```

Run specific checks using tags:

```bash
# Only network and NTP checks
ansible-playbook playbooks/server_audit.yaml --tags network,ntp

# Only KVM and storage checks
ansible-playbook playbooks/server_audit.yaml --tags kvm,drbd,linstor
```

#### Find VM Host

Find which host is running a specific VM:

```bash
ansible-playbook playbooks/vm_finder.yaml -e "vm_name=myvm"
```

#### Configure PCM Resources

Set up floating IP and service resources:

```bash
ansible-playbook playbooks/pcm_resources.yaml
```

With custom parameters:

```bash
ansible-playbook playbooks/pcm_resources.yaml \
  -e "floating_ip=10.0.0.100" \
  -e "service_names=['nginx','postgresql']"
```

#### Check OneIdentity and LINBIT

Check OneIdentity vastool and LINBIT storage:

```bash
ansible-playbook playbooks/oneidentity_linbit_check.yaml
```

Check only specific components:

```bash
# Only vastool
ansible-playbook playbooks/oneidentity_linbit_check.yaml --tags vastool

# Only DRBD and Linstor
ansible-playbook playbooks/oneidentity_linbit_check.yaml --tags drbd,linstor
```

### Using the Ubuntu Packages Role

#### In a Playbook

```yaml
---
- name: Install packages
  hosts: cluster_nodes
  become: true
  roles:
    - role: ubuntu_packages
      vars:
        ubuntu_packages_list:
          - htop
          - vim
          - curl
```

#### Standalone

```bash
ansible-playbook -i inventory/production/hosts.yaml \
  -e "{ 'ubuntu_packages_list': ['htop', 'vim', 'curl'] }" \
  /dev/stdin <<EOF
---
- hosts: all
  become: true
  roles:
    - ubuntu_packages
EOF
```

## Roles

The repository includes 13 reusable Ansible roles for comprehensive cluster management:

### Core Infrastructure Roles

| Role | Purpose |
|------|---------|
| **cluster_base** | Base cluster configuration, system setup, and user management |
| **cluster_network** | Network configuration (bonds, VLANs, bridges) |
| **cluster_monitoring** | Zabbix agent installation and monitoring setup |
| **cluster_identity** | OneIdentity vastool, Kerberos, SSSD configuration |
| **cluster_cockpit** | Cockpit web interface setup and configuration |

### Storage & HA Roles

| Role | Purpose |
|------|---------|
| **cluster_drbd** | DRBD storage replication setup and configuration |
| **cluster_linstor** | Linstor distributed storage management |
| **cluster_storage** | Storage configuration and LVM management |
| **cluster_pacemaker** | Pacemaker/Corosync HA cluster setup |

### Virtualization Roles

| Role | Purpose |
|------|---------|
| **cluster_vm** | KVM/libvirt virtual machine management |

### Package Management Roles

| Role | Purpose |
|------|---------|
| **ubuntu_packages** | Ubuntu package installation from file lists |

### Testing Roles

| Role | Purpose |
|------|---------|
| **cck-tests** | Cluster configuration and compatibility tests |

Each role follows Ansible best practices with:
- Pre-installation checks in `tasks/pre_checks.yaml`
- Installation tasks in `tasks/install.yaml`
- Configuration tasks in `tasks/configure.yaml`
- Main orchestration in `tasks/main.yaml`
- Default variables in `defaults/main.yaml`
- Handlers in `handlers/main.yaml`

## Configuration

### Inventory Management

Edit inventory files in `inventory/production/hosts.yaml` or `inventory/staging/hosts.yaml`:

```yaml
all:
  children:
    cluster_nodes:
      hosts:
        node1:
          ansible_host: 192.168.1.101
          ansible_user: admin
```

### Group Variables

Modify group-specific variables in `inventory/*/group_vars/`:

- `all.yaml` - Variables for all hosts
- `cluster_nodes.yaml` - Cluster-specific variables

### Ansible Configuration

Main configuration is in `ansible.cfg`. Key settings:

- **Inventory**: `inventory/production`
- **Logs**: `ansible.log`
- **Forks**: 10 parallel processes
- **Fact caching**: Enabled with JSON backend

## Playbook Details

### Core Infrastructure Playbooks

#### server_audit.yaml

Comprehensive server audit checking:
- Network configuration and connectivity
- NTP/time synchronization
- DNS configuration and resolution
- Authentication settings (SSSD, LDAP)
- User group memberships
- KVM virtual machines
- OneIdentity vastool
- LINBIT Storage (DRBD/linstor)

**Output**: Reports saved to `/tmp/server_audit/`

#### vm_finder.yaml

Locates a VM across cluster nodes by:
1. Checking if VM is running via virsh
2. Checking DRBD primary status if VM not running
3. Executing tasks on the identified host

**Required variable**: `vm_name`

#### pcm_resources.yaml

Configures Pacemaker cluster resources:
- Floating IP address (IPaddr2)
- Systemd service resources
- Resource groups and constraints
- Location preferences and stickiness

**Configurable via inventory** or command-line variables.

#### oneidentity_linbit_check.yaml

Performs detailed checks on:
- **OneIdentity vastool**: version, status, domains, license
- **DRBD**: installation, resources, status, devices
- **Linstor**: nodes, resources, storage pools, volumes

**Output**: Reports saved to `/tmp/vastool_linbit_reports/`

### VM Management Playbooks

#### vm_discovery_playbook.yaml

Discovers and inventories all virtual machines across cluster:
- Lists all VMs and their current state
- Identifies VM host locations
- Generates comprehensive VM reports

#### vm_management.yaml

VM lifecycle management operations:
- Start/stop VMs
- Configure VM resources
- Manage VM state across cluster

#### vm_cdrom_eject.yaml

Manages CD-ROM devices for VMs:
- Ejects virtual CD-ROM media
- Updates VM configurations

#### vm_drbd_pcm.yaml

Integrates VMs with DRBD and Pacemaker:
- Configures VM resources in Pacemaker
- Sets up DRBD integration for VM storage
- Manages VM failover scenarios

### Cluster Setup

#### cluster_setup.yaml

Main cluster orchestration playbook that coordinates:
- Initial cluster configuration
- Role deployment
- Service initialization

## Tags

All playbooks support tags for selective execution:

| Playbook | Available Tags |
|----------|----------------|
| server_audit.yaml | network, ntp, time, dns, auth, security, users, kvm, virtualization, drbd, linstor, storage, vastool, report |
| vm_finder.yaml | virsh, kvm, drbd, storage, execute |
| pcm_resources.yaml | install, prerequisites, service, check, idempotency, resources, floating-ip, services, group, constraints, stickiness, location, verify, validate |
| oneidentity_linbit_check.yaml | vastool, identity, auth, drbd, linstor, storage, linbit, report |

## Environment Switching

To switch between environments:

```bash
# Use staging
ansible-playbook -i inventory/staging/hosts.yaml playbooks/server_audit.yaml

# Use production (default)
ansible-playbook playbooks/server_audit.yaml
```

Or modify `ansible.cfg`:

```ini
[defaults]
inventory = ./inventory/staging
```

## Best Practices

1. **Test in staging first**: Always test playbooks in staging before production
2. **Use tags**: Run specific sections with tags to save time
3. **Check mode**: Use `--check` for dry-run
4. **Limit hosts**: Use `-l hostname` to target specific hosts
5. **Verbose output**: Use `-v`, `-vv`, or `-vvv` for debugging

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Test connectivity
   ansible all -m ping

   # Check SSH config
   ssh -i ~/.ssh/id_rsa admin@192.168.1.101
   ```

2. **Permission Denied**
   ```bash
   # Verify sudo access
   ansible all -b -m command -a "whoami"
   ```

3. **Fact Gathering Failed**
   ```bash
   # Clear fact cache
   rm -rf /tmp/ansible_facts/*
   ```

## Naming Conventions

This repository follows strict naming conventions:

- **Playbooks**: Use `snake_case.yaml` format (e.g., `vm_management.yaml`)
- **Roles**: Use `snake_case` format, prefix cluster roles with `cluster_` (e.g., `cluster_drbd`)
- **Variables**: Use `snake_case` format (e.g., `floating_ip`)
- **File Extensions**: Always use `.yaml` (NOT `.yml`)

See [../CONTRIBUTING.md](../CONTRIBUTING.md) for complete coding standards and contribution guidelines.

## Archived Content

Legacy `.txt` playbook drafts and standalone scripts have been moved to:
- `../docs/archive/original-txt-files/` - Original playbook drafts
- `../docs/archive/shell-scripts/` - Standalone test scripts

The content has been properly refactored into the current Ansible structure.

## Support

For issues or questions:
1. Check the documentation in `docs/`
2. Review playbook headers for usage examples
3. Use `ansible-playbook --help` for command options

## Contributing

When adding new playbooks:
1. Use `.yaml` extension (not `.yml`)
2. Add descriptive headers with usage examples
3. Include tags for selective execution
4. Add error handling with `block`/`rescue`
5. Update this README with new playbook details
