# VM Management Playbooks

Ansible playbooks for managing virtual machines with DRBD storage in a Pacemaker cluster.

## Overview

These playbooks use the `vm_drbd_pcm` role to deploy and manage highly available virtual machines with DRBD-replicated storage managed by Pacemaker.

## Prerequisites

- Pacemaker/Corosync cluster configured
- LINSTOR controller and satellites installed
- DRBD kernel module loaded
- libvirt and qemu-kvm installed
- Network bridge configured

## Playbooks

### deploy_vm.yaml
Deploy a single virtual machine with DRBD storage.

**Usage:**
```bash
ansible-playbook ansible/playbooks/vm-management/deploy_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01
```

### deploy_all_vms.yaml
Deploy all virtual machines defined in the inventory.

**Usage:**
```bash
ansible-playbook ansible/playbooks/vm-management/deploy_all_vms.yaml \
  -i ansible/inventory/vm-management/production.yaml
```

### manage_vm.yaml
Manage VM lifecycle (start, stop, restart, migrate, status).

**Usage:**
```bash
# Check VM status
ansible-playbook ansible/playbooks/vm-management/manage_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01 \
  -e vm_action=status

# Start a VM
ansible-playbook ansible/playbooks/vm-management/manage_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01 \
  -e vm_action=start

# Stop a VM
ansible-playbook ansible/playbooks/vm-management/manage_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01 \
  -e vm_action=stop

# Migrate a VM to another node
ansible-playbook ansible/playbooks/vm-management/manage_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01 \
  -e vm_action=migrate \
  -e target_node=node2

# Restart a VM
ansible-playbook ansible/playbooks/vm-management/manage_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01 \
  -e vm_action=restart

# Cleanup failed resources
ansible-playbook ansible/playbooks/vm-management/manage_vm.yaml \
  -i ansible/inventory/vm-management/production.yaml \
  -e vm_target=vm01 \
  -e vm_action=cleanup
```

## Inventory Configuration

Example inventory is provided in `ansible/inventory/vm-management/`.

### Structure
```
ansible/inventory/vm-management/
├── production.yaml           # Main inventory
├── host_vars/               # Per-VM configuration
│   ├── vm01.yaml
│   ├── vm02.yaml
│   └── vm03.yaml
└── group_vars/              # Group variables
    ├── cluster_nodes.yaml
    └── virtual_machines.yaml
```

### Configuring a VM

Edit `host_vars/vmXX.yaml` for each VM:

```yaml
vm_name: "vm01"
vm_memory: "2048"              # Memory in MiB
vm_vcpus: "2"                  # Number of vCPUs
vm_drbd_resource: "vm01-disk"  # DRBD resource name
vm_storage_size: "20G"         # Storage size
vm_network_bridge: "br0"       # Network bridge
vm_preferred_node: "node1"     # Preferred cluster node
vm_allow_migrate: true         # Allow live migration
vm_enable_stickiness: true     # Enable resource stickiness
vm_stickiness: 150             # Stickiness value
vm_priority: 100               # Resource priority
vm_filesystem_type: "ext4"     # Filesystem type (ext4, xfs)
```

## Role

The playbooks use the `vm_drbd_pcm` role located at `ansible/roles/vm_drbd_pcm/`.

See the role README for detailed documentation: `ansible/roles/vm_drbd_pcm/README.md`

## Features

- **DRBD Storage**: Block-level replication using DRBD and LINSTOR
- **High Availability**: VM failover managed by Pacemaker
- **Live Migration**: Support for live VM migration between nodes
- **Resource Constraints**: Automatic configuration of Pacemaker constraints
- **Idempotent**: Safe to re-run without side effects
- **Verification**: Built-in verification tasks

## Testing

Before deploying to production:

1. **Syntax check:**
   ```bash
   ansible-playbook ansible/playbooks/vm-management/deploy_vm.yaml --syntax-check
   ```

2. **Dry run:**
   ```bash
   ansible-playbook ansible/playbooks/vm-management/deploy_vm.yaml \
     -i ansible/inventory/vm-management/production.yaml \
     --check \
     -e vm_target=vm01
   ```

3. **Deploy to test environment first**

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

## Documentation

- Role README: `ansible/roles/vm_drbd_pcm/README.md`
- Validation Report: `docs/ansible-vm-drbd-validation.md`
- File Rename Summary: `docs/ansible-yml-to-yaml-rename.md`

## Support

For issues or questions, see the main FlexiCluster documentation.
