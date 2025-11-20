#!/bin/bash
# Script to run the PCM floating IP Ansible playbook with parameters

# Default values
FLOATING_IP="192.168.1.100"
FLOATING_IP_CIDR="24"
NETWORK_INTERFACE="eth0"
RESOURCE_GROUP_NAME="floating-ip-group"
SERVICE1="service1"
SERVICE2="service2"
TARGET_HOSTS="cluster_nodes"
INVENTORY_FILE="inventory.ini"
ENABLE_STICKINESS=false
PREFERRED_NODE=""

# Display usage information
function show_usage {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -i, --ip IP              Floating IP address (default: $FLOATING_IP)"
    echo "  -c, --cidr MASK          CIDR netmask (default: $FLOATING_IP_CIDR)"
    echo "  -n, --nic INTERFACE      Network interface (default: $NETWORK_INTERFACE)"
    echo "  -g, --group NAME         Resource group name (default: $RESOURCE_GROUP_NAME)"
    echo "  -s1, --service1 NAME     First service name (default: $SERVICE1)"
    echo "  -s2, --service2 NAME     Second service name (default: $SERVICE2)"
    echo "  -t, --target HOSTS       Target hosts pattern (default: $TARGET_HOSTS)"
    echo "  -f, --inventory FILE     Inventory file (default: $INVENTORY_FILE)"
    echo "  --sticky                 Enable resource stickiness"
    echo "  -p, --prefer NODE        Set preferred node"
    echo "  -h, --help               Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -i|--ip)
            FLOATING_IP="$2"
            shift 2
            ;;
        -c|--cidr)
            FLOATING_IP_CIDR="$2"
            shift 2
            ;;
        -n|--nic)
            NETWORK_INTERFACE="$2"
            shift 2
            ;;
        -g|--group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -s1|--service1)
            SERVICE1="$2"
            shift 2
            ;;
        -s2|--service2)
            SERVICE2="$2"
            shift 2
            ;;
        -t|--target)
            TARGET_HOSTS="$2"
            shift 2
            ;;
        -f|--inventory)
            INVENTORY_FILE="$2"
            shift 2
            ;;
        --sticky)
            ENABLE_STICKINESS=true
            shift
            ;;
        -p|--prefer)
            PREFERRED_NODE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Construct extra vars
EXTRA_VARS="floating_ip=$FLOATING_IP floating_ip_cidr=$FLOATING_IP_CIDR network_interface=$NETWORK_INTERFACE resource_group_name=$RESOURCE_GROUP_NAME service_names=[$SERVICE1,$SERVICE2] target_hosts=$TARGET_HOSTS"

# Add optional parameters if specified
if [ "$ENABLE_STICKINESS" = true ]; then
    EXTRA_VARS="$EXTRA_VARS enable_stickiness=true"
fi

if [ -n "$PREFERRED_NODE" ]; then
    EXTRA_VARS="$EXTRA_VARS preferred_node=$PREFERRED_NODE"
fi

# Run the playbook
echo "Running playbook with the following parameters:"
echo "  Floating IP: $FLOATING_IP/$FLOATING_IP_CIDR on $NETWORK_INTERFACE"
echo "  Resource group: $RESOURCE_GROUP_NAME"
echo "  Services: $SERVICE1, $SERVICE2"
echo "  Target hosts: $TARGET_HOSTS"

ansible-playbook -i "$INVENTORY_FILE" floating_ip_pcm.yml --extra-vars "$EXTRA_VARS"