# Server Network Configuration and Virtualization Documentation

## Overview

This document explains the network setup of the server and its virtual machine configuration. The server uses advanced networking techniques to provide reliable connectivity and support virtual machine networking.

## Server Network Configuration

The server has multiple network interfaces that are combined into logical groups called "bonds" to increase reliability and throughput. Think of bonds as bundling multiple network cables together to create a more robust connection.

### Network Bonds

The server has 5 network bonds:

1. **bond-mgmt**: Management network connection
   - Used for: Server administration and management
   - IP Address: 10.236.146.165
   - Internet access via default gateway: 10.236.146.161
   - Connected physical interfaces: eno7 and eno8 (using active-backup mode for fault tolerance)

2. **bond-int**: Internal network connection
   - Used for: Internal server communication
   - IP Address: 192.168.0.2
   - Connected physical interfaces: ens2f0np0 and ens2f1np1 (using 802.3ad mode for increased bandwidth)

3. **bond-fabric**: Fabric network connection
   - Used for: Specialized data traffic
   - No IP assigned directly to this bond
   - Connected physical interfaces: ens1f0np0 and ens1f1np1 (using 802.3ad mode)

4. **bond-gic**: GIC network connection with multiple VLANs
   - Used for: Communication with GIC (Global Internet Connectivity) networks
   - Connected physical interfaces: ens3f0np0 and ens3f1np1 (using 802.3ad mode)
   - Configured with 3 VLANs (101, 102, and 125)

5. **bond-pfx**: PFX network connection with multiple VLANs
   - Used for: PFX (Prefix) network traffic
   - Connected physical interfaces: eno5 and eno6 (using 802.3ad mode)
   - Has larger MTU (9000) for improved performance
   - Configured with 4 VLANs (2, 3, 4, and 10)

### Virtual Networks (VLANs)

The server uses VLANs to segment network traffic into different logical networks:

1. **GIC VLANs**:
   - VLAN 101: Connected to bridge br-gic101 (10.236.148.197)
   - VLAN 102: Connected to bridge br-gic102 (10.236.148.229)
   - VLAN 125: Connected to bridge br-gic125 (100.79.23.165)

2. **PFX VLANs**:
   - VLAN 2: Connected to bridge br-pfx2 (21.0.16.5) with MTU 9000
   - VLAN 3: Connected to bridge br-pfx3 (21.0.16.69) with MTU 9000
   - VLAN 4: Connected to bridge br-pfx4 (10.237.176.5)
   - VLAN 10: Connected to bridge br-pfx10 (10.9.110.137)

### Network Bridges

Network bridges act as virtual switches that connect virtual machines to physical networks:

1. **br-gic101**: Bridge for VLAN 101
   - IP Address: 10.236.148.197/27
   - Default route: 10.236.148.193

2. **br-gic102**: Bridge for VLAN 102
   - IP Address: 10.236.148.229/27
   - Default route: 10.236.148.225

3. **br-gic125**: Bridge for VLAN 125
   - IP Address: 100.79.23.165/28
   - Default route: 100.79.23.161

4. **br-pfx2**: Bridge for VLAN 2
   - IP Address: 21.0.16.5/26
   - Default route: 21.0.16.1
   - MTU: 9000 (for larger packet sizes)

5. **br-pfx3**: Bridge for VLAN 3
   - IP Address: 21.0.16.69/26
   - Default route: 21.0.16.65
   - MTU: 9000 (for larger packet sizes)

6. **br-pfx4**: Bridge for VLAN 4
   - IP Address: 10.237.176.5/29
   - Default route: 10.237.176.1

7. **br-pfx10**: Bridge for VLAN 10
   - IP Address: 10.9.110.137/26
   - Default route: 10.9.110.129

## Virtualization Configuration (Libvirt)

The server uses libvirt to manage virtual machines. These virtual machines connect to the physical network using the bridges configured above.

### Virtual Networks

The server has 8 virtual networks configured:

1. **default**: Connected to br-gic102
   - Used for: Default virtual machine networking
   - Physical connection: VLAN 102 on bond-gic

2. **FlexiLab-SERO-PF-Data-1**: Connected to br-pfx2
   - Used for: FlexiLab SERO PF Data 1 network
   - Physical connection: VLAN 2 on bond-pfx

3. **FlexiLab-SERO-PF-Data-2**: Connected to br-pfx3
   - Used for: FlexiLab SERO PF Data 2 network
   - Physical connection: VLAN 3 on bond-pfx

4. **VPN02245_FLX_Infra_Management_SERO**: Connected to br-gic101
   - Used for: VPN02245 FlexiLab Infrastructure Management
   - Physical connection: VLAN 101 on bond-gic

5. **VPN03161_FLX_Infra_Management_SERO**: Connected to br-gic102
   - Used for: VPN03161 FlexiLab Infrastructure Management
   - Physical connection: VLAN 102 on bond-gic

6. **VPN03162-FlexiLab-SERO-PF-Management**: Connected to br-pfx10
   - Used for: VPN03162 FlexiLab SERO PF Management
   - Physical connection: VLAN 10 on bond-pfx

7. **VPN05627-DSELab-FL-INFRA-SERO**: Connected to br-pfx4
   - Used for: VPN05627 DSELab FL Infrastructure SERO
   - Physical connection: VLAN 4 on bond-pfx

8. **VPN05632_FLX_Infra_Management_SERO**: Connected to br-gic125
   - Used for: VPN05632 FlexiLab Infrastructure Management SERO
   - Physical connection: VLAN 125 on bond-gic

## Network Flow Diagram

```
Physical Network Interfaces
│
├── eno7 + eno8 ──────────► bond-mgmt (10.236.146.165) ─────► Server Management
│
├── ens2f0np0 + ens2f1np1 ─► bond-int (192.168.0.2) ───────► Internal Communication
│
├── ens1f0np0 + ens1f1np1 ─► bond-fabric ───────────────────► Fabric Network
│
├── ens3f0np0 + ens3f1np1 ─► bond-gic ───┬─► VLAN 101 ──────► br-gic101 ──────► VPN02245_FLX_Infra_Management_SERO
│                                        │
│                                        ├─► VLAN 102 ──────► br-gic102 ──────┬─► default
│                                        │                                    │
│                                        │                                    └─► VPN03161_FLX_Infra_Management_SERO
│                                        │
│                                        └─► VLAN 125 ──────► br-gic125 ──────► VPN05632_FLX_Infra_Management_SERO
│
└── eno5 + eno6 ────────────► bond-pfx ───┬─► VLAN 2 ───────► br-pfx2 ───────► FlexiLab-SERO-PF-Data-1
                                          │
                                          ├─► VLAN 3 ───────► br-pfx3 ───────► FlexiLab-SERO-PF-Data-2
                                          │
                                          ├─► VLAN 4 ───────► br-pfx4 ───────► VPN05627-DSELab-FL-INFRA-SERO
                                          │
                                          └─► VLAN 10 ──────► br-pfx10 ──────► VPN03162-FlexiLab-SERO-PF-Management
```

## Summary

The server uses multiple bonded network interfaces to provide redundancy and increased bandwidth. These bonds connect to various network segments using VLANs. Network bridges connect these VLANs to virtual networks used by virtual machines. This configuration provides a flexible, reliable networking environment for both the physical server and its virtual machines.