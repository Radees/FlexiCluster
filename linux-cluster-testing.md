# Linux Cluster Testing & Recovery Procedures

## Testing Scenario 1: Hardware Failure (Server Down)

### Test Procedure:
1. **Pre-test preparation**:
   - Document current VM inventory and placement
   - Verify cluster health status and quorum configuration
   - Create baseline performance metrics
   - Ensure backups are current

2. **Controlled server failure simulation**:
   - Power off a selected server completely (hard power off)
   - Alternatively, use `ipmi` commands to simulate hardware failure

3. **Monitoring and verification**:
   - Observe cluster behavior and alerts
   - Monitor the time taken for VMs to failover
   - Verify all VMs restart on remaining nodes

4. **Recovery testing**:
   - Bring the failed server back online
   - Monitor rejoin process and resource rebalancing

### Results Collection:
- Failover time for each VM
- Any VMs that failed to migrate properly
- Resource utilization on remaining nodes during failover
- Cluster alert logs
- Time taken for server to rejoin the cluster when restored
- Any manual interventions required

## Testing Scenario 2: SSD Failure

### Test Procedure:
1. **Pre-test preparation**:
   - Map storage dependencies for each VM
   - Document current storage configuration
   - Verify redundancy level of storage (RAID, distributed storage)

2. **Controlled SSD failure simulation**:
   - For hardware RAID: Remove an SSD physically or mark as failed
   - For software-defined storage: Fail a disk using appropriate commands
   - For distributed storage: Simulate disk failure through management interface

3. **Monitoring and verification**:
   - Observe storage subsystem behavior
   - Monitor data rebuild/rebalancing 
   - Verify VM operations continue without interruption

4. **Recovery testing**:
   - Replace the failed SSD
   - Monitor rebuild/resync progress
   - Verify performance during rebuild

### Results Collection:
- Detection time of the failure
- Impact on VM performance during degraded mode
- Time required for data rebuild
- Storage subsystem logs
- Performance metrics during rebuild
- Any data consistency issues

## Testing Scenario 3: Maintenance Mode

### Test Procedure:
1. **Pre-test preparation**:
   - Document current VM placement
   - Verify capacity to handle load with one node offline

2. **Controlled maintenance procedure**:
   - Enable maintenance mode on target server
   - Observe VM migration to other nodes
   - Apply mock patches or updates
   - Exit maintenance mode

3. **Monitoring and verification**:
   - Verify all VMs migrated cleanly
   - Monitor performance during reduced capacity
   - Confirm server properly returns to service

### Results Collection:
- Time to evacuate all VMs from the node
- Resource utilization on remaining nodes
- Any VM migration failures
- Time to return to normal operations
- User-experienced downtime if any

## Testing Scenario 4: Network Issues

### Test Procedure:
1. **Pre-test preparation**:
   - Document network topology and redundancy
   - Verify Link Aggregation Group (LAG) or active-standby configurations

2. **Controlled network failure simulation**:
   - Disconnect specific network ports
   - Simulate port failures using network management tools
   - Test different failure patterns (single port, multiple ports)

3. **Monitoring and verification**:
   - Observe failover to backup links
   - Monitor network throughput and latency
   - Verify VM connectivity is maintained

4. **LAG/active-standby testing**:
   - Fail primary links to force standby activation
   - Test recovery when primary links are restored

### Results Collection:
- Failover time for network paths
- Packet loss during transition
- VM connectivity statistics
- Network interface error logs
- Time to detect and recover from failures
- Bandwidth changes during degraded operation

## Testing Scenario 5: Volume Changes

### Test Procedure:
1. **Pre-test preparation**:
   - Document current volume configuration
   - Create test VMs for volume operations

2. **Volume operation testing**:
   - Create new volumes
   - Attach volumes to running VMs
   - Detach volumes from running VMs
   - Move volumes between storage pools

3. **Monitoring and verification**:
   - Verify volume operations complete successfully
   - Monitor impact on VM operations
   - Test data integrity after changes

### Results Collection:
- Time required for each volume operation
- Any VM disruptions during operations
- Storage performance before and after changes
- Volume operation logs
- Impact on other VMs sharing storage resources

## Testing Scenario 6: Volume at 100% Utilization

### Test Procedure:
1. **Pre-test preparation**:
   - Create test volumes with defined capacity
   - Ensure monitoring is in place for capacity alerts

2. **Controlled volume filling**:
   - Gradually fill volumes to near capacity (90%)
   - Monitor system behavior
   - Continue filling to 100%

3. **Monitoring and verification**:
   - Observe system alerts and behaviors
   - Monitor VM performance degradation
   - Test ability to expand volumes when full

4. **Recovery testing**:
   - Expand volumes to relieve space pressure
   - Clean up excess data
   - Verify normal operations resume

### Results Collection:
- Alert thresholds and timing
- VM performance metrics at different utilization levels
- Time to execute volume expansion
- System behavior at 100% utilization
- Any filesystem corruption or VM failures
- Recovery time to normal operation

## Testing Scenario 7: Services Migration and Interruption

### Test Procedure:
1. **Pre-test preparation**:
   - Document services dependencies
   - Create baseline performance metrics
   - Prepare monitoring for service availability

2. **Controlled service interruption**:
   - Stop critical services (database, web servers, etc.)
   - Interrupt VMs abruptly (power cycle)
   - Reboot VMs
   - Migrate services between hosts

3. **Monitoring and verification**:
   - Measure service recovery time
   - Verify data consistency after interruption
   - Test application functionality after recovery

4. **HA GUI creation testing**:
   - Implement HA for management GUI services
   - Test failover of GUI components
   - Verify management functionality during transitions

### Results Collection:
- Service downtime during each operation
- Application recovery time
- Success rate of automated recoveries
- Manual interventions required
- Data consistency verification results
- HA GUI failover times and functionality gaps

## General Results Collection Methods

For all scenarios, implement these data collection methods:
- Centralized logging solution (ELK stack, Graylog)
- Performance monitoring tools (Prometheus, Grafana)
- Automated screenshot capture of critical alerts
- Script-based timing of key operations
- Service availability monitoring
- Test report template with pass/fail criteria
- Post-test root cause analysis for any issues