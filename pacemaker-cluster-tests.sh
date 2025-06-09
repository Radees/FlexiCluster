#!/bin/bash
# Pacemaker Cluster Failover Testing Script
# Tests service and VM migration following VIP and DRBD resource failover in a 2-node cluster

# Set error handling
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

# Configuration variables - adjust these to match your environment
NODE1="node1"
NODE2="node2"
VIP_RESOURCE="cluster_vip"
VIP_ADDRESS="192.168.1.100"  # Replace with your virtual IP
DRBD_RESOURCE="drbd_resource"  # The DRBD resource name in pacemaker
VM_RESOURCES=("vm_1" "vm_2")  # List of VM resource names in pacemaker
SERVICE_RESOURCES=("apache" "mysql")  # List of service resource names
MOUNT_POINT="/mnt/drbd_test"
LOG_FILE="/var/log/cluster_test_$(date +%Y%m%d_%H%M%S).log"
TEST_TIMEOUT=300  # Maximum time in seconds to wait for resource migration
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

# Create directory for log file if it doesn't exist
mkdir -p $(dirname $LOG_FILE)

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Function to check if we're running on one of the cluster nodes
check_current_node() {
    local hostname=$(hostname -s)
    if [[ "$hostname" != "$NODE1" && "$hostname" != "$NODE2" ]]; then
        log "WARNING: This script should be run from one of the cluster nodes ($NODE1 or $NODE2)"
        log "Current hostname: $hostname"
    fi
    log "Running tests from node: $hostname"
}

# Function to determine the current active node for a resource
get_resource_location() {
    local resource=$1
    local location=$(pcs status resources | grep -A1 "$resource" | grep -oE "Started.*$NODE1|Started.*$NODE2" | awk '{print $NF}')
    if [[ -z "$location" ]]; then
        log "ERROR: Could not determine current location for resource $resource"
        return 1
    fi
    echo $location
}

# Function to check if a node is reachable
check_node_status() {
    local node=$1
    if ping -c 1 -W 2 $node &>/dev/null; then
        log "Node $node is reachable"
        return 0
    else
        log "WARNING: Node $node is not reachable"
        return 1
    fi
}

# Function to wait for a resource to be active on a specific node
wait_for_resource_on_node() {
    local resource=$1
    local target_node=$2
    local timeout=$3
    local start_time=$(date +%s)
    local current_time
    local elapsed_time
    
    log "Waiting for resource $resource to be active on $target_node (timeout: ${timeout}s)"
    
    while true; do
        local current_node=$(get_resource_location $resource)
        
        if [[ "$current_node" == "$target_node" ]]; then
            log "Resource $resource is now active on $target_node"
            return 0
        fi
        
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        
        if [[ $elapsed_time -ge $timeout ]]; then
            log "ERROR: Timeout waiting for resource $resource to migrate to $target_node"
            log "Current location: $current_node"
            return 1
        fi
        
        sleep 5
    done
}

# Function to check if services associated with VIP are running
check_services_status() {
    local node=$1
    local status=0
    
    log "Checking services status on $node"
    
    for service in "${SERVICE_RESOURCES[@]}"; do
        log "Checking service $service on $node"
        if ssh $SSH_OPTS $node "pcs status resources | grep $service | grep -q 'Started'"; then
            log "Service $service is running on $node"
        else
            log "ERROR: Service $service is not running on $node"
            status=1
        fi
    done
    
    return $status
}

# Function to check if DRBD is primary on the specified node
check_drbd_status() {
    local node=$1
    
    log "Checking DRBD status on $node"
    
    if ssh $SSH_OPTS $node "drbdadm role all | grep -q Primary"; then
        log "DRBD is Primary on $node"
        return 0
    else
        log "ERROR: DRBD is not Primary on $node"
        return 1
    fi
}

# Function to check if VMs are running on the specified node
check_vms_status() {
    local node=$1
    local status=0
    
    log "Checking VMs status on $node"
    
    for vm in "${VM_RESOURCES[@]}"; do
        log "Checking VM $vm on $node"
        if ssh $SSH_OPTS $node "pcs status resources | grep $vm | grep -q 'Started'"; then
            log "VM $vm is running on $node"
        else
            log "ERROR: VM $vm is not running on $node"
            status=1
        fi
    done
    
    return $status
}

# Function to perform a controlled migration of a resource
migrate_resource() {
    local resource=$1
    local target_node=$2
    
    log "Migrating resource $resource to node $target_node"
    
    if pcs resource move $resource $target_node; then
        log "Migration command for $resource to $target_node executed successfully"
        if wait_for_resource_on_node $resource $target_node $TEST_TIMEOUT; then
            log "Resource $resource successfully migrated to $target_node"
            return 0
        else
            return 1
        fi
    else
        log "ERROR: Failed to execute migration command for $resource to $target_node"
        return 1
    fi
}

# Function to clear resource constraints after testing
clear_constraints() {
    local resource=$1
    
    log "Clearing constraints for resource $resource"
    
    if pcs resource clear $resource; then
        log "Constraints cleared for $resource"
        return 0
    else
        log "WARNING: Failed to clear constraints for $resource"
        return 1
    fi
}

# Function to test VIP failover
test_vip_failover() {
    log "\n=== Testing VIP Failover ==="
    
    # Get current VIP location
    local current_vip_node=$(get_resource_location $VIP_RESOURCE)
    log "Current VIP location: $current_vip_node"
    
    # Determine the other node for migration
    local target_node
    if [[ "$current_vip_node" == "$NODE1" ]]; then
        target_node=$NODE2
    else
        target_node=$NODE1
    fi
    
    # Check if target node is online
    if ! check_node_status $target_node; then
        log "ERROR: Target node $target_node is not available for testing"
        return 1
    fi
    
    # Migrate VIP to the other node
    log "Initiating VIP migration from $current_vip_node to $target_node"
    if migrate_resource $VIP_RESOURCE $target_node; then
        # Verify VIP is accessible
        if ping -c 3 -W 2 $VIP_ADDRESS &>/dev/null; then
            log "VIP $VIP_ADDRESS is accessible after migration"
            
            # Clear constraints
            clear_constraints $VIP_RESOURCE
            
            return 0
        else
            log "ERROR: VIP $VIP_ADDRESS is not accessible after migration"
            clear_constraints $VIP_RESOURCE
            return 1
        fi
    else
        log "ERROR: VIP migration failed"
        clear_constraints $VIP_RESOURCE
        return 1
    fi
}

# Function to test service failover follows VIP
test_service_failover() {
    log "\n=== Testing Service Failover with VIP ==="
    
    # Get current VIP location
    local current_vip_node=$(get_resource_location $VIP_RESOURCE)
    log "Current VIP location: $current_vip_node"
    
    # Check if services are running on VIP node
    if check_services_status $current_vip_node; then
        log "Services are correctly running on VIP node $current_vip_node"
    else
        log "ERROR: Services are not running correctly on VIP node $current_vip_node"
        return 1
    fi
    
    # Determine the other node for migration
    local target_node
    if [[ "$current_vip_node" == "$NODE1" ]]; then
        target_node=$NODE2
    else
        target_node=$NODE1
    fi
    
    # Check if target node is online
    if ! check_node_status $target_node; then
        log "ERROR: Target node $target_node is not available for testing"
        return 1
    fi
    
    # Migrate VIP to the other node
    log "Initiating VIP migration from $current_vip_node to $target_node"
    if migrate_resource $VIP_RESOURCE $target_node; then
        # Wait for services to follow VIP
        sleep 30
        
        # Verify services migrated to new VIP node
        if check_services_status $target_node; then
            log "Services successfully followed VIP to $target_node"
            
            # Clear constraints
            clear_constraints $VIP_RESOURCE
            
            return 0
        else
            log "ERROR: Services did not follow VIP to $target_node"
            clear_constraints $VIP_RESOURCE
            return 1
        fi
    else
        log "ERROR: VIP migration failed"
        clear_constraints $VIP_RESOURCE
        return 1
    fi
}

# Function to test DRBD failover
test_drbd_failover() {
    log "\n=== Testing DRBD Failover ==="
    
    # Get current DRBD primary location
    local current_drbd_node=$(get_resource_location $DRBD_RESOURCE)
    log "Current DRBD primary location: $current_drbd_node"
    
    # Determine the other node for migration
    local target_node
    if [[ "$current_drbd_node" == "$NODE1" ]]; then
        target_node=$NODE2
    else
        target_node=$NODE1
    fi
    
    # Check if target node is online
    if ! check_node_status $target_node; then
        log "ERROR: Target node $target_node is not available for testing"
        return 1
    fi
    
    # Migrate DRBD to the other node
    log "Initiating DRBD migration from $current_drbd_node to $target_node"
    if migrate_resource $DRBD_RESOURCE $target_node; then
        # Verify DRBD is primary on target node
        if check_drbd_status $target_node; then
            log "DRBD successfully migrated to $target_node"
            
            # Clear constraints
            clear_constraints $DRBD_RESOURCE
            
            return 0
        else
            log "ERROR: DRBD did not properly migrate to $target_node"
            clear_constraints $DRBD_RESOURCE
            return 1
        fi
    else
        log "ERROR: DRBD migration failed"
        clear_constraints $DRBD_RESOURCE
        return 1
    fi
}

# Function to test VM failover follows DRBD
test_vm_failover() {
    log "\n=== Testing VM Failover with DRBD ==="
    
    # Get current DRBD primary location
    local current_drbd_node=$(get_resource_location $DRBD_RESOURCE)
    log "Current DRBD primary location: $current_drbd_node"
    
    # Check if VMs are running on DRBD primary node
    if check_vms_status $current_drbd_node; then
        log "VMs are correctly running on DRBD primary node $current_drbd_node"
    else
        log "ERROR: VMs are not running correctly on DRBD primary node $current_drbd_node"
        return 1
    fi
    
    # Determine the other node for migration
    local target_node
    if [[ "$current_drbd_node" == "$NODE1" ]]; then
        target_node=$NODE2
    else
        target_node=$NODE1
    fi
    
    # Check if target node is online
    if ! check_node_status $target_node; then
        log "ERROR: Target node $target_node is not available for testing"
        return 1
    fi
    
    # Migrate DRBD to the other node
    log "Initiating DRBD migration from $current_drbd_node to $target_node"
    if migrate_resource $DRBD_RESOURCE $target_node; then
        # Wait for VMs to follow DRBD
        sleep 60
        
        # Verify VMs migrated to new DRBD primary node
        if check_vms_status $target_node; then
            log "VMs successfully followed DRBD to $target_node"
            
            # Clear constraints
            clear_constraints $DRBD_RESOURCE
            
            return 0
        else
            log "ERROR: VMs did not follow DRBD to $target_node"
            clear_constraints $DRBD_RESOURCE
            return 1
        fi
    else
        log "ERROR: DRBD migration failed"
        clear_constraints $DRBD_RESOURCE
        return 1
    fi
}

# Function to perform a comprehensive test of cluster services
test_comprehensive() {
    log "\n=== Comprehensive Cluster Test ==="
    
    # Get current resources location
    local current_vip_node=$(get_resource_location $VIP_RESOURCE)
    local current_drbd_node=$(get_resource_location $DRBD_RESOURCE)
    
    log "Current VIP location: $current_vip_node"
    log "Current DRBD primary location: $current_drbd_node"
    
    # Determine the other node for migration
    local target_node
    if [[ "$current_vip_node" == "$NODE1" ]]; then
        target_node=$NODE2
    else
        target_node=$NODE1
    fi
    
    # Check if target node is online
    if ! check_node_status $target_node; then
        log "ERROR: Target node $target_node is not available for testing"
        return 1
    fi
    
    # Migrate VIP to the other node
    log "Initiating comprehensive resource migration from $current_vip_node to $target_node"
    
    # First migrate VIP
    if migrate_resource $VIP_RESOURCE $target_node; then
        log "VIP successfully migrated to $target_node"
        
        # Wait for services to follow
        sleep 30
        
        # Check if services followed
        if check_services_status $target_node; then
            log "Services successfully followed VIP to $target_node"
        else
            log "ERROR: Services did not follow VIP to $target_node"
            clear_constraints $VIP_RESOURCE
            return 1
        fi
        
        # Then migrate DRBD if it's not already on the target node
        if [[ "$current_drbd_node" != "$target_node" ]]; then
            if migrate_resource $DRBD_RESOURCE $target_node; then
                log "DRBD successfully migrated to $target_node"
                
                # Wait for VMs to follow
                sleep 60
                
                # Check if VMs followed
                if check_vms_status $target_node; then
                    log "VMs successfully followed DRBD to $target_node"
                else
                    log "ERROR: VMs did not follow DRBD to $target_node"
                    clear_constraints $VIP_RESOURCE
                    clear_constraints $DRBD_RESOURCE
                    return 1
                fi
            else
                log "ERROR: DRBD migration failed"
                clear_constraints $VIP_RESOURCE
                clear_constraints $DRBD_RESOURCE
                return 1
            fi
        else
            log "DRBD is already on target node $target_node"
            
            # Check if VMs are on the DRBD node
            if check_vms_status $target_node; then
                log "VMs are correctly running on DRBD primary node $target_node"
            else
                log "ERROR: VMs are not running correctly on DRBD primary node $target_node"
                clear_constraints $VIP_RESOURCE
                return 1
            fi
        fi
        
        log "Comprehensive migration test successful"
        clear_constraints $VIP_RESOURCE
        clear_constraints $DRBD_RESOURCE
        return 0
    else
        log "ERROR: VIP migration failed"
        clear_constraints $VIP_RESOURCE
        return 1
    fi
}

# Function to check STONITH configuration
check_stonith() {
    log "\n=== Checking STONITH Configuration ==="
    
    if pcs stonith show &>/dev/null; then
        log "STONITH resources found:"
        pcs stonith show | tee -a $LOG_FILE
        
        # Check if STONITH is enabled
        if pcs property show stonith-enabled | grep -q "stonith-enabled: true"; then
            log "STONITH is enabled in cluster properties"
            return 0
        else
            log "WARNING: STONITH is disabled in cluster properties"
            return 1
        fi
    else
        log "WARNING: No STONITH resources configured"
        return 1
    fi
}

# Function to check cluster configuration
check_cluster_config() {
    log "\n=== Checking Cluster Configuration ==="
    
    # Check cluster status
    log "Cluster status:"
    pcs status | tee -a $LOG_FILE
    
    # Check for resource failures
    log "Checking for resource failures:"
    if pcs status | grep -q "Failed"; then
        log "WARNING: Resource failures detected in cluster"
        pcs status | grep -A5 "Failed" | tee -a $LOG_FILE
        return 1
    else
        log "No resource failures detected"
    fi
    
    # Check corosync configuration
    log "Checking corosync rings:"
    corosync-cfgtool -s | tee -a $LOG_FILE
    
    # Check quorum status
    log "Checking quorum status:"
    corosync-quorumtool | tee -a $LOG_FILE
    
    return 0
}

# Function to simulate a node failure by stopping corosync and pacemaker
simulate_node_failure() {
    local node_to_fail=$1
    local current_node=$(hostname -s)
    
    log "\n=== Simulating Node Failure for $node_to_fail ==="
    
    if [[ "$current_node" == "$node_to_fail" ]]; then
        log "Cannot simulate failure of the current node ($current_node) we're running on"
        return 1
    fi
    
    # Check if target node is online
    if ! check_node_status $node_to_fail; then
        log "ERROR: Node $node_to_fail is already unreachable"
        return 1
    fi
    
    log "Getting current resources location before failure"
    local vip_before=$(get_resource_location $VIP_RESOURCE)
    local drbd_before=$(get_resource_location $DRBD_RESOURCE)
    
    log "VIP before failure: $vip_before"
    log "DRBD before failure: $drbd_before"
    
    # Stop corosync and pacemaker on the node to simulate failure
    log "Stopping cluster services on $node_to_fail"
    if ssh $SSH_OPTS $node_to_fail "systemctl stop pacemaker corosync"; then
        log "Successfully stopped cluster services on $node_to_fail"
        
        # Wait for recovery
        log "Waiting for cluster to recover (60 seconds)..."
        sleep 60
        
        # Check resource locations after failure
        local surviving_node
        if [[ "$node_to_fail" == "$NODE1" ]]; then
            surviving_node=$NODE2
        else
            surviving_node=$NODE1
        fi
        
        log "Checking resources on surviving node $surviving_node"
        
        # Check VIP location
        local vip_after=$(get_resource_location $VIP_RESOURCE)
        log "VIP after failure: $vip_after"
        
        if [[ "$vip_after" == "$surviving_node" ]]; then
            log "VIP successfully failed over to $surviving_node"
        else
            log "ERROR: VIP failover did not occur properly"
        fi
        
        # Check DRBD location
        local drbd_after=$(get_resource_location $DRBD_RESOURCE)
        log "DRBD after failure: $drbd_after"
        
        if [[ "$drbd_after" == "$surviving_node" ]]; then
            log "DRBD successfully failed over to $surviving_node"
        else
            log "ERROR: DRBD failover did not occur properly"
        fi
        
        # Check if services followed the VIP
        if check_services_status $surviving_node; then
            log "Services successfully failed over to $surviving_node"
        else
            log "ERROR: Services did not properly fail over to $surviving_node"
        fi
        
        # Check if VMs followed the DRBD
        if check_vms_status $surviving_node; then
            log "VMs successfully failed over to $surviving_node"
        else
            log "ERROR: VMs did not properly fail over to $surviving_node"
        fi
        
        # Restart the failed node
        log "Restarting cluster services on $node_to_fail"
        ssh $SSH_OPTS $node_to_fail "systemctl start corosync pacemaker"
        
        # Wait for the node to rejoin
        log "Waiting for $node_to_fail to rejoin the cluster (30 seconds)..."
        sleep 30
        
        # Check if the node is back in the cluster
        if pcs status nodes | grep -q "$node_to_fail.*Online"; then
            log "Node $node_to_fail has successfully rejoined the cluster"
            return 0
        else
            log "ERROR: Node $node_to_fail has not rejoined the cluster"
            return 1
        fi
    else
        log "ERROR: Failed to stop cluster services on $node_to_fail"
        return 1
    fi
}

# Function to test resource constraints and ordering
check_resource_constraints() {
    log "\n=== Checking Resource Constraints ==="
    
    # Check for colocation constraints
    log "Checking colocation constraints:"
    pcs constraint colocation show | tee -a $LOG_FILE
    
    # Check for order constraints
    log "Checking order constraints:"
    pcs constraint order show | tee -a $LOG_FILE
    
    # Check location constraints
    log "Checking location constraints:"
    pcs constraint location show | tee -a $LOG_FILE
    
    # Verify specific constraints
    # 1. Check if VMs are colocated with DRBD
    log "Verifying VM/DRBD colocation:"
    for vm in "${VM_RESOURCES[@]}"; do
        if pcs constraint colocation show | grep -q "$vm.*with.*$DRBD_RESOURCE"; then
            log "VM $vm is properly colocated with DRBD"
        else
            log "WARNING: No colocation constraint found between VM $vm and DRBD"
        fi
    done
    
    # 2. Check if services are colocated with VIP
    log "Verifying Service/VIP colocation:"
    for service in "${SERVICE_RESOURCES[@]}"; do
        if pcs constraint colocation show | grep -q "$service.*with.*$VIP_RESOURCE"; then
            log "Service $service is properly colocated with VIP"
        else
            log "WARNING: No colocation constraint found between service $service and VIP"
        fi
    done
    
    return 0
}

# Run all tests
run_all_tests() {
    local failures=0
    
    log "Starting Pacemaker Cluster Tests"
    log "======================================="
    
    # Check current node
    check_current_node
    
    # Check cluster configuration
    check_cluster_config || ((failures++))
    
    # Check STONITH configuration
    check_stonith || log "WARNING: STONITH not properly configured"
    
    # Check resource constraints
    check_resource_constraints || ((failures++))
    
    # Test VIP failover
    test_vip_failover || ((failures++))
    
    # Test service failover
    test_service_failover || ((failures++))
    
    # Test DRBD failover
    test_drbd_failover || ((failures++))
    
    # Test VM failover
    test_vm_failover || ((failures++))
    
    # Comprehensive test
    test_comprehensive || ((failures++))
    
    # Ask for permission to simulate node failure
    read -p "Do you want to simulate a node failure? This will temporarily stop cluster services on the other node. (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        # Determine which node to fail (the one we're not running on)
        local current_node=$(hostname -s)
        local node_to_fail
        
        if [[ "$current_node" == "$NODE1" ]]; then
            node_to_fail=$NODE2
        else
            node_to_fail=$NODE1
        fi
        
        simulate_node_failure $node_to_fail || ((failures++))
    else
        log "Skipping node failure simulation"
    fi

    # Summary
    log "\n======================================="
    log "Test Results Summary"
    log "======================================="
    if [[ $failures -eq 0 ]]; then
        log "All tests PASSED!"
        log "Your Pacemaker cluster appears to be properly configured and functioning"
    else
        log "WARNING: $failures test(s) FAILED"
        log "Please review the log file: $LOG_FILE"
    fi
    log "======================================="
    
    return $failures
}

# Run all tests
run_all_tests
exit $?