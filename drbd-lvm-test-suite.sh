#!/bin/bash
#
# DRBD and LVM Testing Suite
# This script performs tests on DRBD and LVM functionality
#
# Requirements:
# - Root privileges
# - DRBD and LVM properly installed
# - Two nodes with DRBD configured (PRIMARY and SECONDARY roles)
# - Test devices/resources already configured in DRBD configuration

# Exit on error
set -e

# Configuration - modify these variables according to your setup
PRIMARY_NODE="node1"
SECONDARY_NODE="node2"
DRBD_RESOURCE="r0"
DRBD_DEVICE="/dev/drbd0"
TEST_VG="testvg"
TEST_LV="testlv"
TEST_SIZE="500M"
TEST_MOUNT="/mnt/drbd_test"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o BatchMode=yes"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
    fi
    
    # Check if DRBD is installed
    if ! command -v drbdadm &> /dev/null; then
        log_error "DRBD is not installed"
    fi
    
    # Check if LVM is installed
    if ! command -v lvm &> /dev/null; then
        log_error "LVM is not installed"
    fi
    
    # Check if the DRBD resource exists
    if ! drbdadm dump $DRBD_RESOURCE &> /dev/null; then
        log_error "DRBD resource $DRBD_RESOURCE does not exist"
    fi
    
    log_success "All prerequisites met"
}

test_drbd_basic_functionality() {
    log_info "Testing basic DRBD functionality..."
    
    # Get DRBD status
    if ! drbdadm status $DRBD_RESOURCE; then
        log_error "Failed to get DRBD status"
    fi
    
    # Check if DRBD device exists
    if [ ! -e $DRBD_DEVICE ]; then
        log_error "DRBD device $DRBD_DEVICE does not exist"
    fi
    
    # Make this node the primary
    log_info "Setting this node to primary role..."
    if ! drbdadm primary $DRBD_RESOURCE; then
        log_error "Failed to set DRBD resource to primary"
    fi
    
    # Check if the resource is primary
    if ! drbdadm role $DRBD_RESOURCE | grep -q "Primary"; then
        log_error "DRBD resource is not in Primary role"
    fi
    
    log_success "Basic DRBD functionality test passed"
}

test_lvm_on_drbd() {
    log_info "Testing LVM on DRBD..."
    
    # Create a physical volume on DRBD device
    log_info "Creating physical volume on $DRBD_DEVICE"
    if ! pvcreate $DRBD_DEVICE; then
        log_error "Failed to create physical volume on DRBD device"
    fi
    
    # Create a volume group
    log_info "Creating volume group $TEST_VG"
    if ! vgcreate $TEST_VG $DRBD_DEVICE; then
        log_error "Failed to create volume group"
    fi
    
    # Create a logical volume
    log_info "Creating logical volume $TEST_LV"
    if ! lvcreate -L $TEST_SIZE -n $TEST_LV $TEST_VG; then
        log_error "Failed to create logical volume"
    fi
    
    # Create filesystem
    log_info "Creating ext4 filesystem on /dev/$TEST_VG/$TEST_LV"
    if ! mkfs.ext4 /dev/$TEST_VG/$TEST_LV; then
        log_error "Failed to create filesystem"
    fi
    
    # Create mount point
    mkdir -p $TEST_MOUNT
    
    # Mount the filesystem
    log_info "Mounting filesystem to $TEST_MOUNT"
    if ! mount /dev/$TEST_VG/$TEST_LV $TEST_MOUNT; then
        log_error "Failed to mount filesystem"
    fi
    
    # Write test file
    log_info "Writing test data"
    echo "DRBD and LVM test $(date)" > $TEST_MOUNT/testfile.txt
    
    # Sync and verify data is written
    sync
    if [ ! -f $TEST_MOUNT/testfile.txt ]; then
        log_error "Test file not found after creation"
    fi
    
    log_success "LVM on DRBD test passed"
}

test_drbd_failover() {
    log_info "Testing DRBD failover..."
    
    # Unmount filesystem first
    log_info "Unmounting filesystem"
    if ! umount $TEST_MOUNT; then
        log_error "Failed to unmount filesystem"
    fi
    
    # Deactivate the volume group
    log_info "Deactivating volume group"
    if ! vgchange -an $TEST_VG; then
        log_error "Failed to deactivate volume group"
    fi
    
    # Make this node secondary
    log_info "Setting this node to secondary role"
    if ! drbdadm secondary $DRBD_RESOURCE; then
        log_error "Failed to set node to secondary role"
    fi
    
    # Make the other node primary
    log_info "Setting the other node to primary role"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "drbdadm primary $DRBD_RESOURCE"; then
        log_error "Failed to set secondary node to primary role"
    fi
    
    # Verify the other node is primary
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "drbdadm role $DRBD_RESOURCE | grep -q 'Primary'"; then
        log_error "Secondary node failed to become primary"
    fi
    
    # Activate the volume group on the other node
    log_info "Activating volume group on secondary node"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "vgchange -ay $TEST_VG"; then
        log_error "Failed to activate volume group on secondary node"
    fi
    
    # Mount the filesystem on the other node
    log_info "Mounting filesystem on secondary node"
    ssh $SSH_OPTIONS $SECONDARY_NODE "mkdir -p $TEST_MOUNT"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "mount /dev/$TEST_VG/$TEST_LV $TEST_MOUNT"; then
        log_error "Failed to mount filesystem on secondary node"
    fi
    
    # Verify data consistency
    log_info "Verifying data consistency"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "grep -q 'DRBD and LVM test' $TEST_MOUNT/testfile.txt"; then
        log_error "Data consistency check failed"
    fi
    
    log_success "DRBD failover test passed"
}

test_drbd_failback() {
    log_info "Testing DRBD failback..."
    
    # Unmount filesystem on secondary node
    log_info "Unmounting filesystem on secondary node"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "umount $TEST_MOUNT"; then
        log_error "Failed to unmount filesystem on secondary node"
    fi
    
    # Deactivate volume group on secondary node
    log_info "Deactivating volume group on secondary node"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "vgchange -an $TEST_VG"; then
        log_error "Failed to deactivate volume group on secondary node"
    fi
    
    # Make secondary node secondary again
    log_info "Setting secondary node back to secondary role"
    if ! ssh $SSH_OPTIONS $SECONDARY_NODE "drbdadm secondary $DRBD_RESOURCE"; then
        log_error "Failed to set secondary node back to secondary role"
    fi
    
    # Make this node primary again
    log_info "Setting this node back to primary role"
    if ! drbdadm primary $DRBD_RESOURCE; then
        log_error "Failed to set this node back to primary role"
    fi
    
    # Activate volume group
    log_info "Re-activating volume group"
    if ! vgchange -ay $TEST_VG; then
        log_error "Failed to re-activate volume group"
    fi
    
    # Mount filesystem
    log_info "Re-mounting filesystem"
    if ! mount /dev/$TEST_VG/$TEST_LV $TEST_MOUNT; then
        log_error "Failed to re-mount filesystem"
    fi
    
    # Check data consistency
    log_info "Verifying data consistency after failback"
    if ! grep -q "DRBD and LVM test" $TEST_MOUNT/testfile.txt; then
        log_error "Data consistency check failed after failback"
    fi
    
    log_success "DRBD failback test passed"
}

test_lvm_snapshot() {
    log_info "Testing LVM snapshot functionality..."
    
    # Create a snapshot
    log_info "Creating LVM snapshot"
    if ! lvcreate -L 100M -s -n ${TEST_LV}_snap /dev/$TEST_VG/$TEST_LV; then
        log_error "Failed to create LVM snapshot"
    fi
    
    # Create mount point for snapshot
    mkdir -p ${TEST_MOUNT}_snap
    
    # Mount the snapshot
    log_info "Mounting snapshot"
    if ! mount /dev/$TEST_VG/${TEST_LV}_snap ${TEST_MOUNT}_snap; then
        log_error "Failed to mount snapshot"
    fi
    
    # Verify data in snapshot
    log_info "Verifying data in snapshot"
    if ! grep -q "DRBD and LVM test" ${TEST_MOUNT}_snap/testfile.txt; then
        log_error "Data verification in snapshot failed"
    fi
    
    # Modify original data
    log_info "Modifying original data"
    echo "Modified data $(date)" >> $TEST_MOUNT/testfile.txt
    
    # Verify original data is changed but snapshot remains the same
    if ! grep -q "Modified data" $TEST_MOUNT/testfile.txt; then
        log_error "Failed to modify original data"
    fi
    
    if grep -q "Modified data" ${TEST_MOUNT}_snap/testfile.txt; then
        log_error "Snapshot data changed when it shouldn't have"
    fi
    
    # Unmount snapshot
    log_info "Unmounting snapshot"
    if ! umount ${TEST_MOUNT}_snap; then
        log_error "Failed to unmount snapshot"
    fi
    
    # Remove snapshot
    log_info "Removing snapshot"
    if ! lvremove -f /dev/$TEST_VG/${TEST_LV}_snap; then
        log_error "Failed to remove snapshot"
    fi
    
    log_success "LVM snapshot test passed"
}

test_drbd_resize() {
    log_info "Testing DRBD resize functionality..."
    
    # Unmount the filesystem first
    log_info "Unmounting filesystem"
    if ! umount $TEST_MOUNT; then
        log_error "Failed to unmount filesystem"
    fi
    
    # Deactivate the volume group
    log_info "Deactivating volume group"
    if ! vgchange -an $TEST_VG; then
        log_error "Failed to deactivate volume group"
    fi
    
    # Remove LVM objects
    log_info "Removing logical volume"
    if ! lvremove -f /dev/$TEST_VG/$TEST_LV; then
        log_error "Failed to remove logical volume"
    fi
    
    log_info "Removing volume group"
    if ! vgremove $TEST_VG; then
        log_error "Failed to remove volume group"
    fi
    
    log_info "Removing physical volume"
    if ! pvremove $DRBD_DEVICE; then
        log_error "Failed to remove physical volume"
    fi
    
    # Make nodes secondary for resize
    log_info "Setting both nodes to secondary for resize"
    drbdadm secondary $DRBD_RESOURCE
    ssh $SSH_OPTIONS $SECONDARY_NODE "drbdadm secondary $DRBD_RESOURCE"
    
    # Resize the underlying DRBD device
    log_info "Resizing DRBD device"
    if ! drbdadm resize $DRBD_RESOURCE; then
        log_error "Failed to resize DRBD device"
    fi
    
    # Make this node primary again
    log_info "Setting this node back to primary"
    if ! drbdadm primary $DRBD_RESOURCE; then
        log_error "Failed to set node back to primary"
    fi
    
    log_success "DRBD resize test passed"
}

cleanup() {
    log_info "Cleaning up test environment..."
    
    # Unmount if mounted
    if mount | grep -q $TEST_MOUNT; then
        umount $TEST_MOUNT
    fi
    
    if mount | grep -q ${TEST_MOUNT}_snap; then
        umount ${TEST_MOUNT}_snap
    fi
    
    # Deactivate and remove LVM objects if they exist
    if lvs | grep -q $TEST_LV; then
        lvremove -f /dev/$TEST_VG/$TEST_LV
    fi
    
    if lvs | grep -q ${TEST_LV}_snap; then
        lvremove -f /dev/$TEST_VG/${TEST_LV}_snap
    fi
    
    if vgs | grep -q $TEST_VG; then
        vgremove -f $TEST_VG
    fi
    
    if pvs | grep -q $DRBD_DEVICE; then
        pvremove -f $DRBD_DEVICE
    fi
    
    # Ensure DRBD is in a clean state
    drbdadm secondary $DRBD_RESOURCE
    ssh $SSH_OPTIONS $SECONDARY_NODE "drbdadm secondary $DRBD_RESOURCE"
    
    log_success "Cleanup completed"
}

# Run all tests
run_all_tests() {
    check_prerequisites
    
    trap cleanup EXIT
    
    test_drbd_basic_functionality
    test_lvm_on_drbd
    test_drbd_failover
    test_drbd_failback
    test_lvm_snapshot
    test_drbd_resize
    
    log_success "All tests completed successfully"
}

# Script usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --all               Run all tests"
    echo "  --drbd-basic        Test basic DRBD functionality"
    echo "  --lvm-on-drbd       Test LVM on DRBD"
    echo "  --failover          Test DRBD failover"
    echo "  --failback          Test DRBD failback"
    echo "  --lvm-snapshot      Test LVM snapshot"
    echo "  --drbd-resize       Test DRBD resize"
    echo "  --cleanup           Clean up test environment"
    echo "  --help              Print this help message"
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    print_usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            run_all_tests
            exit 0
            ;;
        --drbd-basic)
            check_prerequisites
            test_drbd_basic_functionality
            exit 0
            ;;
        --lvm-on-drbd)
            check_prerequisites
            test_lvm_on_drbd
            exit 0
            ;;
        --failover)
            check_prerequisites
            test_drbd_failover
            exit 0
            ;;
        --failback)
            check_prerequisites
            test_drbd_failback
            exit 0
            ;;
        --lvm-snapshot)
            check_prerequisites
            test_lvm_snapshot
            exit 0
            ;;
        --drbd-resize)
            check_prerequisites
            test_drbd_resize
            exit 0
            ;;
        --cleanup)
            cleanup
            exit 0
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
    shift
done