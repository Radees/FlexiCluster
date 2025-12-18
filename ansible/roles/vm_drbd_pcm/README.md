# VM DRBD Pacemaker Ansible Role

This Ansible role manages virtual machines with DRBD storage in a Pacemaker cluster using LINSTOR.

## Directory Structure

```
.
├── ansible.cfg                          # Ansible configuration
├── inventory/
│   ├── production.yaml                  # Main inventory file
│   ├── host_vars/                      # Per-VM variables
│   │   ├── vm01.yaml
│   │   ├── vm02.yaml
│   │   └── vm03.yaml
│   └── group_vars/                     # Group variables
│       ├── cluster_nodes.yaml
│       └── virtual_machines.yaml
├── playbooks/
│   ├── deploy_vm.yaml                   # Deploy single VM
│   ├── deploy_all_vms.yaml              # Deploy all VMs
│   └── manage_vm.yaml                   # Manage VM lifecycle
└── roles/
    └── vm_drbd_pcm/                    # Main role
        ├── tasks/
        │   ├── main.yaml                # Main task orchestration
        │   ├── linstor.yaml             # LINSTOR resource creation
        │   ├── vm_config.yaml           # VM XML configuration
        │   ├── pacemaker.yaml           # Pacemaker resource creation
        │   ├── constraints.yaml         # Resource constraints
        │   └── verify.yaml              # Verification tasks
        ├── defaults/
        │   └── main.yaml                # Default variables
        ├── handlers/
        │   └── main.yaml                # Service handlers
        ├── templates/
        │   └── vm_template.xml.j2      # libvirt VM template
        └── meta/
            └── main.yaml                # Role metadata
```

## Quick Start

### 1. Configure Inventory

Edit `inventory/production.yaml` with your cluster nodes and VM definitions:

```yaml
cluster_nodes:
  hosts:
    node1:
      ansible_host: 192.168.1.10
    node2:
      ansible_host: 192.168.1.11
```

### 2. Configure VMs

Edit host_vars for each VM (e.g., `inventory/host_vars/vm01.yaml`):

```yaml
vm_name: "vm01"
vm_memory: "2048"
vm_vcpus: "2"
vm_drbd_resource: "vm01-disk"
vm_storage_size: "20G"
vm_preferred_node: "node1"
```

### 3. Deploy VMs

Deploy a single VM:
```bash
ansible-playbook playbooks/deploy_vm.yaml -e vm_target=vm01
```

Deploy all VMs:
```bash
ansible-playbook playbooks/deploy_all_vms.yaml
```

### 4. Manage VMs

Start a VM:
```bash
ansible-playbook playbooks/manage_vm.yaml -e vm_target=vm01 -e vm_action=start
```

Stop a VM:
```bash
ansible-playbook playbooks/manage_vm.yaml -e vm_target=vm01 -e vm_action=stop
```

Migrate a VM:
```bash
ansible-playbook playbooks/manage_vm.yaml -e vm_target=vm01 -e vm_action=migrate -e target_node=node2
```

Check VM status:
```bash
ansible-playbook playbooks/manage_vm.yaml -e vm_target=vm01 -e vm_action=status
```

## Role Variables

### Required Variables

- `vm_name` - Name of the VM
- `vm_drbd_resource` - DRBD resource name
- `vm_storage_size` - Storage size (e.g., "20G")

### Optional Variables

- `vm_memory` - Memory in MiB (default: "2048")
- `vm_vcpus` - Number of vCPUs (default: "2")
- `vm_network_bridge` - Network bridge (default: "br0")
- `vm_preferred_node` - Preferred cluster node
- `vm_allow_migrate` - Allow VM migration (default: true)
- `vm_enable_stickiness` - Enable resource stickiness (default: false)
- `vm_stickiness` - Stickiness value (default: 100)
- `vm_priority` - Resource priority (default: 100)
- `vm_filesystem_type` - Filesystem type (default: "ext4")
- `vm_use_linstor` - Use LINSTOR for storage (default: true)

## Features

- **DRBD Storage**: Block-level replication using DRBD and LINSTOR
- **High Availability**: VM failover managed by Pacemaker
- **Live Migration**: Support for live VM migration between nodes
- **Resource Constraints**: Automatic configuration of Pacemaker constraints
- **Idempotent**: Safe to re-run without side effects
- **Verification**: Built-in verification tasks

## Requirements

### Cluster Nodes

- Ubuntu 20.04 or 22.04
- Pacemaker and Corosync configured
- LINSTOR controller and satellite
- DRBD kernel module
- libvirt and qemu-kvm
- Network bridge configured

### Control Node

- Ansible 2.9 or later
- SSH access to cluster nodes
- sudo privileges

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Pacemaker Cluster                  │
├─────────────────┬───────────────────────────────┤
│   Node 1        │           Node 2              │
│                 │                               │
│ ┌─────────────┐ │ ┌─────────────┐              │
│ │   VM (KVM)  │ │ │  VM (standby)│              │
│ └──────┬──────┘ │ └──────┬──────┘              │
│        │        │        │                      │
│ ┌──────▼──────┐ │ ┌──────▼──────┐              │
│ │ DRBD Primary│◄┼─┤DRBD Secondary│              │
│ └─────────────┘ │ └─────────────┘              │
│        │        │        │                      │
│ ┌──────▼──────┐ │ ┌──────▼──────┐              │
│ │   LINSTOR   │ │ │   LINSTOR   │              │
│ └─────────────┘ │ └─────────────┘              │
└─────────────────┴───────────────────────────────┘
```

## Extracted from Concatenated Files

This structure was extracted from:
- `vm_drbd_role.txt` - Role files (10 files)
- `inventory_structure.txt` - Inventory and playbooks (10 files)

Total files extracted: **20 files**

## License

MIT

## Author

Generated from concatenated Ansible configuration files
