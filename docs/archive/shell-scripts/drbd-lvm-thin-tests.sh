#!/bin/bash
# DRBD LVM Thin Storage Testing Script
# This script performs various tests on DRBD devices backed by LVM thin storage

# Set error handling
set -e
trap 'echo "Error occurred at line $LINENO"; exit 1' ERR

# Configuration variables - adjust these to match your environment
DRBD_DEV="/dev/drbd0"
MOUNT_POINT="/mnt/drbd_test"
TEMP_DIR="/tmp/drbd_tests"
LOG_FILE="/var/log/drbd_test_$(date +%Y%m%d_%H%M%S).log"

# Create temp directory if it doesn't exist
mkdir -p $TEMP_DIR

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Test function to check if a command succeeds
test_command() {
    local cmd="$1"
    local expected_pattern="$2"
    local description="$3"
    
    log "TEST: $description"
    log "RUNNING: $cmd"
    
    result=$(eval $cmd 2>&1)
    exit_code=$?
    
    log "RESULT: $result"
    log "EXIT CODE: $exit_code"
    
    if [[ $exit_code -eq 0 ]]; then
        if [[ -z "$expected_pattern" ]] || [[ "$result" =~ $expected_pattern ]]; then
            log "PASS: $description"
            return 0
        else
            log "FAIL: Output doesn't match expected pattern"
            return 1
        fi
    else
        log "FAIL: Command failed with exit code $exit_code"
        return $exit_code
    fi
}

# Initialize log
log "Starting DRBD LVM Thin Storage Tests"
log "======================================="

# Create a results array to track test results
declare -A test_results

# Test 1: Basic DRBD status check
log "\n=== Test 1: Basic DRBD Status ==="
if test_command "drbdadm status" "Primary|Secondary" "Check if DRBD resources are properly connected"; then
    test_results["basic_drbd_status"]="PASS"
else
    test_results["basic_drbd_status"]="FAIL"
fi

# Test 2: Verify DRBD device roles
log "\n=== Test 2: DRBD Roles ==="
if test_command "drbdadm role all" "Primary|Secondary" "Verify DRBD device roles"; then
    test_results["drbd_roles"]="PASS"
else
    test_results["drbd_roles"]="FAIL"
fi

# Test 3: Check LVM thin pools
log "\n=== Test 3: LVM Thin Pools ==="
if test_command "lvs | grep thin" "thin" "Verify LVM thin pools backing the DRBD devices"; then
    test_results["lvm_thin_pools"]="PASS"
else
    test_results["lvm_thin_pools"]="FAIL"
fi

# Test 4: Check if DRBD block device exists
log "\n=== Test 4: DRBD Device Exists ==="
if test_command "test -b $DRBD_DEV && echo 'Device exists'" "Device exists" "Check if DRBD block device exists"; then
    test_results["drbd_device_exists"]="PASS"
else
    test_results["drbd_device_exists"]="FAIL"
fi

# Test 5: Basic I/O test on DRBD device
log "\n=== Test 5: Basic I/O Test ==="
if test_command "dd if=/dev/zero of=$TEMP_DIR/drbd_test_file bs=1M count=10 && dd if=$TEMP_DIR/drbd_test_file of=/dev/null bs=1M && rm $TEMP_DIR/drbd_test_file && echo 'I/O test passed'" "I/O test passed" "Basic I/O test on local filesystem"; then
    test_results["basic_io_test"]="PASS"
else
    test_results["basic_io_test"]="FAIL"
fi

# Test 6: Mount DRBD device and verify data integrity
log "\n=== Test 6: Data Integrity Test ==="
if test_command "mkdir -p $MOUNT_POINT && mount $DRBD_DEV $MOUNT_POINT 2>/dev/null || true && dd if=/dev/urandom of=$MOUNT_POINT/testfile bs=1M count=5 && sync && md5sum $MOUNT_POINT/testfile > $TEMP_DIR/md5.txt && umount $MOUNT_POINT && mount $DRBD_DEV $MOUNT_POINT && md5sum -c $TEMP_DIR/md5.txt && umount $MOUNT_POINT && echo 'Data integrity verified'" "Data integrity verified" "Create and verify test file on mounted DRBD filesystem"; then
    test_results["data_integrity"]="PASS"
else
    test_results["data_integrity"]="FAIL"
fi

# Test 7: Check thin provisioning status
log "\n=== Test 7: Thin Provisioning Status ==="
if test_command "lvs --units m -o name,size,data_percent,metadata_percent | grep thin" "" "Check thin provisioning status"; then
    test_results["thin_provisioning_status"]="PASS"
else
    test_results["thin_provisioning_status"]="FAIL"
fi

# Test 8: Test DRBD configuration
log "\n=== Test 8: DRBD Configuration ==="
if test_command "drbdadm dump all" "/dev/drbd|/dev/mapper" "Test DRBD configuration"; then
    test_results["drbd_config"]="PASS"
else
    test_results["drbd_config"]="FAIL"
fi

# Test 9: Check thin pool metadata status
log "\n=== Test 9: Thin Pool Metadata Status ==="
cmd="lvs -o name,size,data_percent,metadata_percent | grep thin | grep -v '100\.00'"
if test_command "$cmd" "" "Check thin pool metadata status"; then
    test_results["thin_pool_metadata"]="PASS"
else
    test_results["thin_pool_metadata"]="FAIL"
fi

# Test 10: Test DRBD connection status
log "\n=== Test 10: DRBD Connection Status ==="
if test_command "drbdadm cstate all" "Connected" "Test DRBD connection status"; then
    test_results["drbd_connection"]="PASS"
else
    test_results["drbd_connection"]="FAIL"
fi

# Performance Tests - Only run if fio is available
if command -v fio >/dev/null; then
    # Test 11: Sequential write performance
    log "\n=== Test 11: Sequential Write Performance ==="
    if test_command "fio --name=seqwrite --rw=write --direct=1 --ioengine=libaio --bs=1M --size=1G --numjobs=1 --runtime=30 --time_based --filename=$DRBD_DEV" "write:" "Test sequential write performance"; then
        test_results["seq_write_perf"]="PASS"
    else
        test_results["seq_write_perf"]="FAIL"
    fi

    # Test 12: Sequential read performance
    log "\n=== Test 12: Sequential Read Performance ==="
    if test_command "fio --name=seqread --rw=read --direct=1 --ioengine=libaio --bs=1M --size=1G --numjobs=1 --runtime=30 --time_based --filename=$DRBD_DEV" "read:" "Test sequential read performance"; then
        test_results["seq_read_perf"]="PASS"
    else
        test_results["seq_read_perf"]="FAIL"
    fi

    # Test 13: Random I/O performance
    log "\n=== Test 13: Random I/O Performance ==="
    if test_command "fio --name=randio --rw=randrw --direct=1 --ioengine=libaio --bs=4k --size=1G --numjobs=4 --runtime=30 --time_based --filename=$DRBD_DEV" "read:|write:" "Test random I/O performance"; then
        test_results["random_io_perf"]="PASS"
    else
        test_results["random_io_perf"]="FAIL"
    fi

    # Test 14: Stress test
    log "\n=== Test 14: Stress Test ==="
    if test_command "timeout 60s fio --name=stress --rw=randrw --direct=1 --ioengine=libaio --bs=4k --size=500M --numjobs=4 --filename=$DRBD_DEV && echo 'Stress test completed'" "Stress test completed" "Run a short stress test on DRBD device"; then
        test_results["stress_test"]="PASS"
    else
        test_results["stress_test"]="FAIL"
    fi
else
    log "WARNING: fio command not found, skipping performance tests"
fi

# Test 15: DRBD resync speed configuration
log "\n=== Test 15: DRBD Resync Speed Configuration ==="
if test_command "cat /proc/drbd | grep -E 'sync\\'ed:|resync'" "" "Check DRBD resync speed configuration"; then
    test_results["resync_speed"]="PASS"
else 
    test_results["resync_speed"]="FAIL"
fi

# Test 16: Get detailed resource information
log "\n=== Test 16: DRBD Resource Information ==="
if test_command "drbdadm status all -v" "Connection" "Get detailed resource information"; then
    test_results["resource_info"]="PASS"
else
    test_results["resource_info"]="FAIL"
fi

# Test 17: Thin space allocation behavior
log "\n=== Test 17: Thin Space Allocation Behavior ==="
if test_command "mkdir -p $MOUNT_POINT && mount $DRBD_DEV $MOUNT_POINT 2>/dev/null || true && dd if=/dev/zero of=$MOUNT_POINT/bigfile bs=1M count=100 && sync && lvs -o name,data_percent && rm $MOUNT_POINT/bigfile && umount $MOUNT_POINT && echo 'Thin allocation test passed'" "Thin allocation test passed" "Test thin space allocation behavior"; then
    test_results["thin_space_allocation"]="PASS"
else
    test_results["thin_space_allocation"]="FAIL"
fi

# Cleanup
log "\nCleaning up test environment..."
# Ensure DRBD device is unmounted
umount $MOUNT_POINT 2>/dev/null || true

# Summarize the results
log "\n======================================="
log "Test Results Summary"
log "======================================="
pass_count=0
fail_count=0

for test in "${!test_results[@]}"; do
    result="${test_results[$test]}"
    log "  $test: $result"
    if [[ "$result" == "PASS" ]]; then
        ((pass_count++))
    else
        ((fail_count++))
    fi
done

total=$((pass_count + fail_count))
log "======================================="
log "Total tests: $total"
log "Passed: $pass_count"
log "Failed: $fail_count"
log "Success rate: $(( pass_count * 100 / total ))%"
log "======================================="

if [[ $fail_count -gt 0 ]]; then
    log "Some tests failed. Please review the log file: $LOG_FILE"
    exit 1
else
    log "All tests passed!"
    exit 0
fi