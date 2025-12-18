#!/bin/bash
#
# Pacemaker Cluster Documentation Generator
# Collects comprehensive information from 2-node Pacemaker clusters
# Supports SERO and SELI locations with Ubuntu 24.04, DRBD/LINSTOR storage
#
# Usage: ./cluster-documentation-generator.sh [location]
#        location: sero or seli (optional, will prompt if not provided)

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_BASE_DIR="${SCRIPT_DIR}/cluster-documentation"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cluster node definitions
declare -A CLUSTER_NODES
CLUSTER_NODES[seli]="seliics02058 seliics02501"
CLUSTER_NODES[sero]="seroics02744 seroics95861"

# Hardware specifications
declare -A NODE_HARDWARE
NODE_HARDWARE[seroics02744]="ProLiant DL360 Gen10"
NODE_HARDWARE[seroics95861]="ProLiant DL360 Gen10"
NODE_HARDWARE[seliics02058]="DELL POWEREDGE R640"
NODE_HARDWARE[seliics02501]="DELL POWEREDGE R640"

# Network information
declare -A MGMT_NETWORK
MGMT_NETWORK[sero]="VPN01562_FLX_Infra_Management_SERO 10.236.146.160/27"
MGMT_NETWORK[seli]="VPN01562_FLX_Infra_Management 10.142.30.0/27"

# Storage network (same for all)
STORAGE_NETWORK="192.168.0.0/30"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print info messages
print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to safely run a command and capture output
run_command() {
    local cmd="$1"
    local output_var="$2"
    
    if eval "$cmd" 2>&1; then
        return 0
    else
        echo "Command failed or not available"
        return 1
    fi
}

# Function to collect hardware information
collect_hardware_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting hardware information from $hostname..."
    
    cat > "$output_file" << EOF
# Hardware Information: $hostname
**Generated:** $(date)
**Category:** Hardware Specifications

---

EOF
    
    cat >> "$output_file" << 'EOF'
## System Information
```
EOF
    
    run_command "hostnamectl" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## DMI/SMBIOS Information
```
EOF
    run_command "sudo dmidecode -t system" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## CPU Information
```
EOF
    run_command "lscpu" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Memory Information
```
EOF
    run_command "free -h" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Block Devices
```
EOF
    run_command "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL,SERIAL" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## PCI Devices
```
EOF
    run_command "lspci" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect OS information
collect_os_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting OS information from $hostname..."
    
    cat > "$output_file" << EOF
# Operating System Information: $hostname
**Generated:** $(date)
**Category:** Operating System

---

EOF
    
    cat >> "$output_file" << 'EOF'
## OS Release
```
EOF
    run_command "cat /etc/os-release" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Kernel Version
```
EOF
    run_command "uname -a" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Installed Cluster Packages
```
EOF
    run_command "dpkg -l | grep -E 'pacemaker|corosync|pcs|drbd|linstor|libvirt|qemu|cockpit'" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## System Uptime
```
EOF
    run_command "uptime" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect network information
collect_network_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting network information from $hostname..."
    
    cat > "$output_file" << EOF
# Network Configuration: $hostname
**Generated:** $(date)
**Category:** Network

---

EOF
    
    cat >> "$output_file" << 'EOF'
## IP Addresses
```
EOF
    run_command "ip addr show" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Network Links
```
EOF
    run_command "ip link show" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Routing Table
```
EOF
    run_command "ip route show" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Network Bridges
```
EOF
    run_command "bridge link show" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Netplan Configuration
```
EOF
    run_command "cat /etc/netplan/*.yaml" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Network Status
```
EOF
    run_command "networkctl status" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Open Ports
```
EOF
    run_command "ss -tuln" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect storage information
collect_storage_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting storage information from $hostname..."
    
    cat > "$output_file" << EOF
# Storage Configuration: $hostname
**Generated:** $(date)
**Category:** Storage

---

EOF
    
    cat >> "$output_file" << 'EOF'
## Physical Volumes
```
EOF
    run_command "sudo pvs -o +pv_used,pv_free,pv_uuid" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Volume Groups
```
EOF
    run_command "sudo vgs -o +vg_free,vg_size,vg_uuid" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Logical Volumes
```
EOF
    run_command "sudo lvs -o +lv_size,data_percent,metadata_percent,pool_lv,lv_uuid" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Detailed LVM Display
```
EOF
    run_command "sudo lvdisplay -m" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Mount Points
```
EOF
    run_command "df -h" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Disk Usage by Type
```
EOF
    run_command "lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect DRBD information
collect_drbd_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting DRBD information from $hostname..."
    
    cat > "$output_file" << EOF
# DRBD Configuration: $hostname
**Generated:** $(date)
**Category:** DRBD Replication

---

EOF
    
    cat >> "$output_file" << 'EOF'
## DRBD Status
```
EOF
    run_command "sudo drbdadm status" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## DRBD Roles
```
EOF
    run_command "sudo drbdadm role all" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## DRBD Configuration Dump
```
EOF
    run_command "sudo drbdadm dump all" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## DRBD Proc Status
```
EOF
    run_command "sudo cat /proc/drbd" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect LINSTOR information
collect_linstor_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting LINSTOR information from $hostname..."
    
    # Check if linstor-controller service is running
    # Return codes: 0=active, 1=inactive/failed, 3=not loaded/disabled, 4=no such unit
    local controller_running=false
    local controller_status=""
    
    if systemctl is-active --quiet linstor-controller 2>/dev/null; then
        controller_running=true
        controller_status="running"
        print_info "LINSTOR controller is running - collecting full LINSTOR information"
    else
        local status_check
        status_check=$(systemctl is-enabled linstor-controller 2>/dev/null || echo "not-found")
        
        case "$status_check" in
            enabled)
                controller_status="stopped"
                print_info "LINSTOR controller is installed but stopped - skipping LINSTOR cluster commands"
                ;;
            disabled)
                controller_status="disabled"
                print_info "LINSTOR controller is disabled - skipping LINSTOR cluster commands"
                ;;
            *)
                controller_status="not-installed"
                print_info "LINSTOR controller is not installed - skipping LINSTOR cluster commands"
                ;;
        esac
    fi
    
    cat > "$output_file" << EOF
# LINSTOR Configuration: $hostname
**Generated:** $(date)
**Category:** LINSTOR Storage Management

---

EOF
    
    cat >> "$output_file" << 'EOF'

# LINSTOR Configuration

EOF

    if [ "$controller_running" = true ]; then
        cat >> "$output_file" << 'EOF'
## LINSTOR Nodes
```
EOF
        run_command "sudo linstor node list" >> "$output_file"
        echo '```' >> "$output_file"
        
        cat >> "$output_file" << 'EOF'

## LINSTOR Storage Pools
```
EOF
        run_command "sudo linstor storage-pool list" >> "$output_file"
        echo '```' >> "$output_file"
        
        cat >> "$output_file" << 'EOF'

## LINSTOR Resources
```
EOF
        run_command "sudo linstor resource list" >> "$output_file"
        echo '```' >> "$output_file"
        
        cat >> "$output_file" << 'EOF'

## LINSTOR Resource Definitions
```
EOF
        run_command "sudo linstor resource-definition list" >> "$output_file"
        echo '```' >> "$output_file"
        
        cat >> "$output_file" << 'EOF'

## LINSTOR Volumes
```
EOF
        run_command "sudo linstor volume list" >> "$output_file"
        echo '```' >> "$output_file"
    else
        cat >> "$output_file" << EOF
## LINSTOR Controller Status

**Note:** LINSTOR controller is ${controller_status} on this node. LINSTOR cluster commands are skipped.
This node is likely running only the LINSTOR satellite service.

EOF
    fi
    
    cat >> "$output_file" << 'EOF'

## LINSTOR Controller Status
```
EOF
    run_command "sudo systemctl status linstor-controller || true" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## LINSTOR Satellite Status
```
EOF
    run_command "sudo systemctl status linstor-satellite || true" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect Pacemaker cluster information
collect_pacemaker_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting Pacemaker cluster information from $hostname..."
    
    cat > "$output_file" << EOF
# Pacemaker Cluster: $hostname
**Generated:** $(date)
**Category:** Pacemaker

---

EOF
    
    cat >> "$output_file" << 'EOF'
## Cluster Status
```
EOF
    run_command "sudo pcs status" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Cluster Configuration
```
EOF
    run_command "sudo pcs config" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Cluster Properties
```
EOF
    run_command "sudo pcs property list" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Resource Configuration
```
EOF
    run_command "sudo pcs resource status" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Resource Defaults
```
EOF
    run_command "sudo pcs resource defaults" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Constraints
```
EOF
    run_command "sudo pcs constraint list" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## STONITH/Fencing Configuration
```
EOF
    run_command "sudo pcs stonith status" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Node Attributes
```
EOF
    run_command "sudo pcs node attribute" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect Corosync information
collect_corosync_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting Corosync information from $hostname..."
    
    cat > "$output_file" << EOF
# Corosync Configuration: $hostname
**Generated:** $(date)
**Category:** Corosync

---

EOF
    
    cat >> "$output_file" << 'EOF'
## Corosync Configuration File
```
EOF
    run_command "sudo cat /etc/corosync/corosync.conf" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Corosync Membership
```
EOF
    run_command "sudo corosync-cmapctl" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Quorum Status
```
EOF
    run_command "sudo corosync-quorumtool" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Corosync Service Status
```
EOF
    run_command "sudo systemctl status corosync || true" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect VM information
collect_vm_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting VM information from $hostname..."
    
    cat > "$output_file" << EOF
# Virtual Machines: $hostname
**Generated:** $(date)
**Category:** Virtual Machines

---

EOF
    
    cat >> "$output_file" << 'EOF'
## VM List
```
EOF
    run_command "sudo virsh list --all" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## VM Details
```
EOF
    for vm in $(sudo virsh list --name --all 2>/dev/null); do
        if [ -n "$vm" ]; then
            echo "### VM: $vm" >> "$output_file"
            echo '```' >> "$output_file"
            run_command "sudo virsh dominfo '$vm'" >> "$output_file"
            echo '```' >> "$output_file"
            echo "" >> "$output_file"
        fi
    done
    
    cat >> "$output_file" << 'EOF'

## Storage Pools
```
EOF
    run_command "sudo virsh pool-list --all" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Virtual Networks
```
EOF
    run_command "sudo virsh net-list --all" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Libvirtd Service Status
```
EOF
    run_command "sudo systemctl status libvirtd || true" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to collect Cockpit information
collect_cockpit_info() {
    local hostname="$1"
    local output_file="$2"
    
    print_info "Collecting Cockpit information from $hostname..."
    
    cat > "$output_file" << EOF
# Cockpit Management: $hostname
**Generated:** $(date)
**Category:** Cockpit

---

EOF
    
    cat >> "$output_file" << 'EOF'
## Cockpit Service Status
```
EOF
    run_command "sudo systemctl status cockpit || true" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Cockpit Socket Status
```
EOF
    run_command "sudo systemctl status cockpit.socket || true" >> "$output_file"
    echo '```' >> "$output_file"
    
    cat >> "$output_file" << 'EOF'

## Installed Cockpit Packages
```
EOF
    run_command "dpkg -l | grep cockpit" >> "$output_file"
    echo '```' >> "$output_file"
}

# Function to create a comprehensive summary
create_cluster_summary() {
    local location="$1"
    local output_dir="$2"
    local summary_file="${output_dir}/CLUSTER_SUMMARY.md"
    
    print_info "Creating cluster summary for $location..."
    
    cat > "$summary_file" << EOF
# Cluster Documentation Summary
**Location:** ${location^^}
**Generated:** $(date)
**Cluster Nodes:** ${CLUSTER_NODES[$location]}
**Management Network:** ${MGMT_NETWORK[$location]}
**Storage Network:** ${STORAGE_NETWORK}

---

## Documentation Structure

This documentation package contains detailed information about the ${location^^} Pacemaker cluster.

### Contents:

This documentation uses a **multi-file structure** for easy navigation.
Each node has its own directory with categorized documentation files.

EOF

    for node in ${CLUSTER_NODES[$location]}; do
        cat >> "$summary_file" << EOF
#### Node: ${node}/ (${NODE_HARDWARE[$node]})
- [00-INDEX.md](./${node}/00-INDEX.md) - Table of contents and navigation
- [01-Hardware.md](./${node}/01-Hardware.md) - Hardware specifications
- [02-Operating-System.md](./${node}/02-Operating-System.md) - OS details
- [03-Network.md](./${node}/03-Network.md) - Network configuration
- [04-Storage.md](./${node}/04-Storage.md) - Storage layout
- [05-DRBD.md](./${node}/05-DRBD.md) - DRBD status
- [06-LINSTOR.md](./${node}/06-LINSTOR.md) - LINSTOR configuration
- [07-Pacemaker.md](./${node}/07-Pacemaker.md) - Pacemaker cluster
- [08-Corosync.md](./${node}/08-Corosync.md) - Corosync config
- [09-Virtual-Machines.md](./${node}/09-Virtual-Machines.md) - VM inventory
- [10-Cockpit.md](./${node}/10-Cockpit.md) - Cockpit status
- [${node}-FULL.md](./${node}/${node}-FULL.md) - Complete consolidated view

EOF
    done
    
    cat >> "$summary_file" << 'EOF'

---

## Directory Structure

```
cluster-documentation/<location>_<timestamp>/
├── CLUSTER_SUMMARY.md          # This file - overview and quick reference
├── <node1>/                    # Node 1 documentation directory
│   ├── 00-INDEX.md            # Navigation and table of contents
│   ├── 01-Hardware.md         # Hardware specifications
│   ├── 02-Operating-System.md # OS and package information
│   ├── 03-Network.md          # Network configuration
│   ├── 04-Storage.md          # Storage and LVM
│   ├── 05-DRBD.md             # DRBD replication
│   ├── 06-LINSTOR.md          # LINSTOR storage management
│   ├── 07-Pacemaker.md        # Cluster management
│   ├── 08-Corosync.md         # Cluster communication
│   ├── 09-Virtual-Machines.md # VM inventory
│   ├── 10-Cockpit.md          # Web interface
│   └── <node1>-FULL.md        # Consolidated single file
└── <node2>/                    # Node 2 documentation directory
    └── (same structure as node1)
```

**Benefits of Multi-File Structure:**
- 📁 Easy navigation to specific topics
- 🔍 Quick access to relevant information
- 📊 Cleaner organization for version control
- 🔗 Better linking between related topics
- 💾 Smaller individual files for faster loading

**When to use which file:**
- **Individual files (01-*.md)**: When you need specific information
- **INDEX file**: When browsing or searching for topics
- **FULL file**: When you need complete documentation offline or for printing

EOF
    
    cat >> "$summary_file" << EOF

---

## Quick Reference

### Cluster Nodes
EOF

    for node in ${CLUSTER_NODES[$location]}; do
        echo "- **${node}** - ${NODE_HARDWARE[$node]}" >> "$summary_file"
    done
    
    cat >> "$summary_file" << EOF

### Key Components
- **OS:** Ubuntu 24.04 LTS
- **Cluster Stack:** Pacemaker + Corosync + PCS
- **Storage:** DRBD + LINSTOR (LVM thin pools)
- **Virtualization:** KVM/libvirt
- **Management:** Cockpit Web UI

### Network Configuration

#### Management Network
- ${MGMT_NETWORK[$location]}

#### Storage Network  
- ${STORAGE_NETWORK}

#### VM Networks (${location^^})
EOF

    if [[ "$location" == "sero" ]]; then
        cat >> "$summary_file" << 'EOF'
- **VPN03162-FlexiLab-SERO-PF-Management** (10.9.110.128/26) - VLAN 10 - br-pfx10
- **VPN02245_FLX_Infra_Management_SERO** (10.236.148.192/27) - VLAN 101 - br-gic101
- **VPN03161_FLX_Infra_Management_SERO** (10.236.148.224/27) - VLAN 102 - br-gic102 (default)
- **VPN05632_FLX_Infra_Management_SERO** (100.79.23.160/28) - VLAN 125 - br-gic125
- **VPN05627-DSELab-FL-INFRA-SERO** - br-pfx4
- **FlexiLab-SERO-PF-Data-1** (21.0.16.0/26) - VLAN 2 - br-pfx2
- **FlexiLab-SERO-PF-Data-2** (21.0.16.64/26) - VLAN 3 - br-pfx3
EOF
    else
        cat >> "$summary_file" << 'EOF'
- **FlexiLab-SELI-PF-Data-1** (192.168.4.0/23) - VLAN 25 - br-pfx25
- **FlexiLab-SELI-PF-Data-2** (192.168.6.0/23) - VLAN 26 - br-pfx26
- **VPN03162-FlexiLab-SELI-PF-Management** (10.228.226.128/26) - VLAN 29 - br-pfx29
- **VPN03161_FLX_Infra_Management** (10.142.13.192/27) - VLAN 317 - br-gic317 (default)
- **VPN02245_FLX_Infra_Management** (10.142.19.128/27) - VLAN 318 - br-gic318
- **VPN03162_FLX_Infra_Management** (10.142.20.128/26) - VLAN 319 - br-gic319
EOF
    fi

    cat >> "$summary_file" << EOF

### Storage Layout (${location^^})
EOF

    if [[ "$location" == "sero" ]]; then
        cat >> "$summary_file" << 'EOF'

**Volume Groups:**
- linstor_lv_part_pool: 1.66 TB (2 PVs, 21 LVs)
- rootvg: 41.96 GB (1 PV, 2 LVs)

**Thin Pool:**
- lv_part_pool: 1.66 TB (Data: 50.84%, Meta: 25.14%)
EOF
    else
        cat >> "$summary_file" << 'EOF'

**Volume Groups:**
- linstor_lv_part_pool: 1.66 TB (2 PVs, 9 LVs)
- linstor_lv_phys_pool: 3.49 TB (2 PVs, 16 LVs, 446.88 GB free)
- root-vg: 43.94 GB (1 PV, 2 LVs)

**Thin Pools:**
- lv_part_pool: 1.66 TB (Data: 57.81%, Meta: 23.82%)
- lv_phys_pool: 3.06 TB (Data: 42.79%, Meta: 10.40%)
EOF
    fi

    cat >> "$summary_file" << 'EOF'

### Common Commands

#### Cluster Status
```bash
pcs status
pcs resource status
pcs constraint list
```

#### Storage Status
```bash
linstor node list
linstor resource list
drbdadm status
lvs
```

#### VM Management
```bash
virsh list --all
virsh dominfo <vm-name>
```

---

## Important Files

- Corosync Config: `/etc/corosync/corosync.conf`
- DRBD Config: `/etc/drbd.d/`
- LINSTOR Config: `/etc/linstor/`
- Libvirt Config: `/etc/libvirt/`
- Netplan Config: `/etc/netplan/`

---

## Next Steps

1. Review individual node documentation files
2. Verify configurations match expected values
3. Update any outdated information
4. Store this documentation in version control

---

*Generated by cluster-documentation-generator.sh*
EOF

    print_success "Cluster summary created: $summary_file"
}

# Main function to collect all information from a node
collect_node_documentation() {
    local hostname="$1"
    local output_dir="$2"
    
    # Create subdirectory for this node
    local node_dir="${output_dir}/${hostname}"
    mkdir -p "$node_dir"
    
    print_header "Collecting Documentation for $hostname"
    print_info "Output directory: $node_dir"
    
    # Create main index file
    local index_file="${node_dir}/00-INDEX.md"
    cat > "$index_file" << EOF
# Cluster Node Documentation: $hostname
**Generated:** $(date)
**Script Version:** 1.2
**Node Directory:** ${hostname}/

---

## Documentation Files

This directory contains comprehensive documentation for cluster node **${hostname}**.
Each aspect of the system is documented in a separate file for easy navigation.

### Available Documentation

1. **[01-Hardware.md](./01-Hardware.md)** - Hardware specifications
   - System information (manufacturer, model, serial)
   - CPU, memory, and storage devices
   - PCI devices and hardware components

2. **[02-Operating-System.md](./02-Operating-System.md)** - Operating system details
   - OS version and kernel information
   - Installed cluster packages
   - System uptime and boot information

3. **[03-Network.md](./03-Network.md)** - Network configuration
   - Network interfaces and IP addresses
   - Routing tables and network bridges
   - Netplan configuration
   - Open ports and connections

4. **[04-Storage.md](./04-Storage.md)** - Storage configuration
   - LVM physical volumes, volume groups, logical volumes
   - Thin pool configuration and usage
   - Mount points and disk usage
   - Block device information

5. **[05-DRBD.md](./05-DRBD.md)** - DRBD replication status
   - DRBD resource status and roles
   - Replication state and configuration
   - Connection status between nodes

6. **[06-LINSTOR.md](./06-LINSTOR.md)** - LINSTOR storage management
   - LINSTOR node and resource status
   - Storage pool configuration
   - Volume definitions and allocations
   - Controller and satellite service status

7. **[07-Pacemaker.md](./07-Pacemaker.md)** - Pacemaker cluster configuration
   - Cluster status and health
   - Resource configuration and status
   - Constraints and location preferences
   - STONITH/fencing configuration

8. **[08-Corosync.md](./08-Corosync.md)** - Corosync cluster communication
   - Corosync configuration
   - Cluster membership and quorum
   - Communication ring status

9. **[09-Virtual-Machines.md](./09-Virtual-Machines.md)** - Virtual machine inventory
   - VM list and configurations
   - VM resource allocations
   - Storage pools and virtual networks
   - Libvirt service status

10. **[10-Cockpit.md](./10-Cockpit.md)** - Cockpit management interface
    - Cockpit service status
    - Installed Cockpit packages
    - Web interface accessibility

---

## Quick Navigation

- **Hardware issues?** → See [01-Hardware.md](./01-Hardware.md)
- **Network problems?** → See [03-Network.md](./03-Network.md)
- **Storage full?** → See [04-Storage.md](./04-Storage.md)
- **DRBD not syncing?** → See [05-DRBD.md](./05-DRBD.md)
- **Cluster issues?** → See [07-Pacemaker.md](./07-Pacemaker.md)
- **VM problems?** → See [09-Virtual-Machines.md](./09-Virtual-Machines.md)

---

## Collection Information

- **Hostname:** ${hostname}
- **Collection Date:** $(date)
- **Script Version:** 1.2
- **Output Format:** Multi-file (categorized)

---

*This documentation was automatically generated by cluster-documentation-generator.sh*
EOF

    # Collect information into separate files
    print_info "Collecting hardware information..."
    collect_hardware_info "$hostname" "${node_dir}/01-Hardware.md"
    
    print_info "Collecting OS information..."
    collect_os_info "$hostname" "${node_dir}/02-Operating-System.md"
    
    print_info "Collecting network configuration..."
    collect_network_info "$hostname" "${node_dir}/03-Network.md"
    
    print_info "Collecting storage configuration..."
    collect_storage_info "$hostname" "${node_dir}/04-Storage.md"
    
    print_info "Collecting DRBD status..."
    collect_drbd_info "$hostname" "${node_dir}/05-DRBD.md"
    
    print_info "Collecting LINSTOR information..."
    collect_linstor_info "$hostname" "${node_dir}/06-LINSTOR.md"
    
    print_info "Collecting Pacemaker cluster info..."
    collect_pacemaker_info "$hostname" "${node_dir}/07-Pacemaker.md"
    
    print_info "Collecting Corosync configuration..."
    collect_corosync_info "$hostname" "${node_dir}/08-Corosync.md"
    
    print_info "Collecting VM inventory..."
    collect_vm_info "$hostname" "${node_dir}/09-Virtual-Machines.md"
    
    print_info "Collecting Cockpit status..."
    collect_cockpit_info "$hostname" "${node_dir}/10-Cockpit.md"
    
    # Create a consolidated file as well for those who prefer single file
    local consolidated_file="${node_dir}/${hostname}-FULL.md"
    print_info "Creating consolidated documentation file..."
    
    cat > "$consolidated_file" << EOF
# Cluster Node Documentation: $hostname (Consolidated)
**Generated:** $(date)
**Script Version:** 1.2

---

**Note:** This is a consolidated view of all documentation.
For easier navigation, see individual category files in this directory.
See [00-INDEX.md](./00-INDEX.md) for the table of contents.

---

EOF
    
    # Append all category files to consolidated file
    cat "${node_dir}/01-Hardware.md" >> "$consolidated_file"
    cat "${node_dir}/02-Operating-System.md" >> "$consolidated_file"
    cat "${node_dir}/03-Network.md" >> "$consolidated_file"
    cat "${node_dir}/04-Storage.md" >> "$consolidated_file"
    cat "${node_dir}/05-DRBD.md" >> "$consolidated_file"
    cat "${node_dir}/06-LINSTOR.md" >> "$consolidated_file"
    cat "${node_dir}/07-Pacemaker.md" >> "$consolidated_file"
    cat "${node_dir}/08-Corosync.md" >> "$consolidated_file"
    cat "${node_dir}/09-Virtual-Machines.md" >> "$consolidated_file"
    cat "${node_dir}/10-Cockpit.md" >> "$consolidated_file"
    
    cat >> "$consolidated_file" << EOF

---

# End of Documentation for $hostname
**Collection completed:** $(date)

*This documentation was automatically generated by cluster-documentation-generator.sh*
EOF
    
    print_success "Documentation for $hostname completed!"
    print_info "  Index file: ${node_dir}/00-INDEX.md"
    print_info "  Category files: ${node_dir}/01-*.md through 10-*.md"
    print_info "  Consolidated file: ${node_dir}/${hostname}-FULL.md"
}

# Function to display usage
show_usage() {
    cat << EOF
Usage: $0 [location]

Generate comprehensive documentation for Pacemaker clusters.

Arguments:
    location    Cluster location (sero or seli) - optional, will prompt if not provided

Options:
    -h, --help  Display this help message

Examples:
    $0 sero     # Generate documentation for SERO cluster
    $0 seli     # Generate documentation for SELI cluster
    $0          # Interactive mode - will prompt for location

Output:
    Documentation will be saved to: ${OUTPUT_BASE_DIR}/<location>_<timestamp>/

EOF
}

# Main script execution
main() {
    local location="$1"
    
    # Show usage if help requested
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    print_header "Pacemaker Cluster Documentation Generator"
    
    # Prompt for location if not provided
    if [ -z "$location" ]; then
        echo "Available locations:"
        echo "  1) sero - Nodes: ${CLUSTER_NODES[sero]}"
        echo "  2) seli - Nodes: ${CLUSTER_NODES[seli]}"
        echo ""
        read -p "Select location (sero/seli): " location
    fi
    
    # Convert to lowercase and validate
    location=$(echo "$location" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$location" != "sero" ]] && [[ "$location" != "seli" ]]; then
        print_error "Invalid location: $location"
        print_info "Valid locations are: sero, seli"
        exit 1
    fi
    
    # Create output directory
    local output_dir="${OUTPUT_BASE_DIR}/${location}_${TIMESTAMP}"
    mkdir -p "$output_dir"
    
    print_success "Output directory created: $output_dir"
    print_info "Cluster location: ${location^^}"
    print_info "Cluster nodes: ${CLUSTER_NODES[$location]}"
    
    # Check if we can reach the nodes
    local current_host=$(hostname -s)
    print_info "Running from: $current_host"
    
    # Determine if we're running from a cluster node or remotely
    local nodes=(${CLUSTER_NODES[$location]})
    local is_cluster_node=false
    
    for node in "${nodes[@]}"; do
        if [[ "$current_host" == "$node" ]]; then
            is_cluster_node=true
            break
        fi
    done
    
    if [ "$is_cluster_node" = true ]; then
        print_success "Running from cluster node - will collect local information"
        collect_node_documentation "$current_host" "$output_dir"
        
        print_info "To collect information from other node, run this script on that node"
        print_info "Or use SSH to copy and execute remotely"
    else
        print_info "Running from external host - attempting remote collection via SSH"
        print_info "Ensure SSH keys are configured for passwordless access"
        
        for node in "${nodes[@]}"; do
            print_info "Attempting to collect from $node..."
            if ssh -o ConnectTimeout=5 "$node" "echo 'SSH connection successful'" &>/dev/null; then
                # Copy script to remote node
                scp "$0" "${node}:/tmp/cluster-doc-generator.sh" &>/dev/null
                # Execute on remote node
                ssh "$node" "sudo bash /tmp/cluster-doc-generator.sh $location"
                # Copy results back
                scp "${node}:${output_dir}/${node}.md" "$output_dir/" &>/dev/null
                print_success "Collected documentation from $node"
            else
                print_error "Cannot connect to $node via SSH - skipping"
                print_info "You can run this script directly on $node to collect its information"
            fi
        done
    fi
    
    # Create cluster summary
    create_cluster_summary "$location" "$output_dir"
    
    print_header "Documentation Generation Complete"
    print_success "Documentation saved to: $output_dir"
    print_info "Review the files and update any missing information"
    
    # List generated files
    echo ""
    echo "Generated files:"
    ls -lh "$output_dir"
}

# Run main function with all arguments
main "$@"
