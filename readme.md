# PCM Floating IP and Services

This project provides an Ansible playbook to configure a floating IP address in a PCM (Pacemaker) cluster, along with two systemd services that will migrate together with the IP address.

## Requirements

- A working cluster with Pacemaker, Corosync, and PCS installed on the nodes
- Ansible installed on the control machine
- SSH access to the cluster nodes
- Sudo privileges on the cluster nodes

## Files

- `floating_ip_pcm.yml`: The main Ansible playbook that configures PCM resources
- `run_playbook.sh`: A helper script to run the playbook with parameters

## Usage

1. Configure your Ansible inventory file with your cluster nodes:

```ini
# inventory.ini
[cluster_nodes]
node1 ansible_host=192.168.1.101
node2 ansible_host=192.168.1.102
node3 ansible_host=192.168.1.103
```

2. Customize and run the playbook using the helper script:

```bash
# Make the script executable
chmod +x run_playbook.sh

# Run with default values
./run_playbook.sh

# Run with custom values
./run_playbook.sh --ip 10.0.0.100 --cidr 24 --nic eth1 --service1 webapp --service2 database

# Show all available options
./run_playbook.sh --help
```

## What the Playbook Does

1. Verifies that PCM (Pacemaker) and related packages are installed
2. Creates a floating IP resource using the IPaddr2 resource agent
3. Creates systemd service resources for two specified services
4. Groups the floating IP and service resources into a single resource group
5. Sets constraints to ensure the resources move together
6. Displays the status of the configured resources

## Advanced Features

The playbook also supports:

- Setting resource stickiness to prevent unnecessary failovers
- Configuring a preferred node for the resource group

## PCM Commands Used

The playbook uses the following PCM commands behind the scenes:

- `pcs resource create floating_ip IPaddr2 ...`: Creates the floating IP resource
- `pcs resource create service_name systemd:service_name ...`: Creates systemd service resources
- `pcs resource group add group_name resources...`: Groups resources together
- `pcs constraint colocation add group with INFINITY`: Ensures resources stay together
- `pcs resource meta group resource-stickiness=value`: Sets resource stickiness
- `pcs constraint location group prefers node=value`: Sets preferred node

## Customization

You can customize the following variables in the playbook or through the script:

- `floating_ip`: The floating IP address to create
- `floating_ip_cidr`: The CIDR netmask for the floating IP
- `network_interface`: The network interface to attach the IP to
- `resource_group_name`: The name for the PCM resource group
- `service_names`: The names of the systemd services to include

## Troubleshooting

If you encounter issues:

1. Check if the cluster is properly running: `pcs status`
2. Verify the resource configuration: `pcs resource show`
3. Check for any constraint issues: `pcs constraint`
4. Review the cluster logs: `journalctl -u pacemaker`