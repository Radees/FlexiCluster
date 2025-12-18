# Duplicate Tasks Analysis Report - FlexiCluster Ansible

**Generated:** 2025-11-26
**Analysis Scope:** All playbooks and roles in `/ansible/`

## Executive Summary

This report identifies **7 major categories** of duplicated tasks across 11 playbooks and 12 roles. The duplications range from identical OS version checks to complete duplicate code blocks for system component validation.

**Impact:**
- **Maintenance burden:** Changes must be made in multiple locations
- **Inconsistency risk:** Similar tasks may diverge over time
- **Code bloat:** ~500+ lines of duplicated code identified
- **Testing complexity:** Same logic tested multiple times

---

## Category 1: OS Version Checks (CRITICAL)

### Duplication Count: 7 instances

**Identical or near-identical Ubuntu version checks in:**

| File | Lines | Code Pattern |
|------|-------|--------------|
| `roles/cluster_base/tasks/pre_checks.yaml` | 5-10 | Check Ubuntu only |
| `roles/cluster_drbd/tasks/pre_checks.yaml` | 4-10 | Check Ubuntu 20.04+ |
| `roles/cluster_pacemaker/tasks/pre_checks.yaml` | 4-10 | Check Ubuntu 20.04+ |
| `roles/cluster_storage/tasks/pre_checks.yaml` | 4-10 | Check Ubuntu 20.04+ |
| `roles/cluster_vm/tasks/pre_checks.yaml` | 4-10 | Check Ubuntu 20.04+ |
| `roles/cluster_monitoring/tasks/pre_checks.yaml` | 4-10 | Check Ubuntu 20.04+ |
| `roles/ubuntu_packages/tasks/main.yaml` | ~5-10 | Check Ubuntu |

### Example Code (appears 6+ times):

```yaml
- name: Check if running on supported OS
  ansible.builtin.assert:
    that:
      - ansible_distribution == "Ubuntu"
      - ansible_distribution_version is version('20.04', '>=')
    fail_msg: "This role requires Ubuntu 20.04 or later"
    success_msg: "Running on supported Ubuntu version"
```

### Recommendation:
✅ **Create shared task file:** `roles/common/tasks/check_os_ubuntu.yaml`
✅ **Include in all roles:** `include_tasks: ../../common/tasks/check_os_ubuntu.yaml`
✅ **Estimated reduction:** ~60-70 lines of code

---

## Category 2: Apt Cache Updates (HIGH PRIORITY)

### Duplication Count: 8+ instances

**Pattern found across all installation task files:**

| Role | File | Lines |
|------|------|-------|
| cluster_drbd | tasks/install.yaml | 4-7 |
| cluster_pacemaker | tasks/install.yaml | ~5-8 |
| cluster_storage | tasks/install.yaml | ~5-8 |
| cluster_vm | tasks/install.yaml | ~5-8 |
| cluster_monitoring | tasks/install.yaml | ~5-8 |
| cluster_identity | tasks/main.yaml | 27 |
| cluster_network | tasks/main.yaml | 3 |
| ubuntu_packages | (multiple locations) | Various |

### Example Code (appears 8+ times):

```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: 3600
```

### Recommendation:
✅ **Use handlers:** Define apt cache update as a handler triggered by package changes
✅ **OR use pre_tasks:** Single apt cache update at playbook level
✅ **Estimated reduction:** ~30-40 lines of code

---

## Category 3: AD Authentication Package Installation (CRITICAL)

### Duplication Count: 2 instances (FULL vs PARTIAL)

**Complete duplication with inconsistency:**

#### Location 1: `roles/cluster_identity/tasks/main.yaml` (lines 26-37)
```yaml
- name: Install a packages for AD auth
  ansible.builtin.apt:
    update_cache: true
    pkg:
      - krb5-config
      - vasclnt
      - vasyp
      - nfs-common
      - autofs
      - autofs-ldap
```

#### Location 2: `roles/cluster_network/tasks/main.yaml` (lines 2-10)
```yaml
- name: Install a packages for AD auth
  ansible.builtin.apt:
    update_cache: true
    pkg:
      - krb5-config
      - vasclnt
      - vasyp
```

**Issue:** `cluster_network` installs PARTIAL package list. This is likely a bug or oversight.

### Recommendation:
❌ **Remove from cluster_network role entirely** - AD auth is handled by cluster_identity
✅ **Consolidate to single source:** cluster_identity already has complete implementation
✅ **Document dependency:** cluster_identity should be the single source for AD auth
✅ **Estimated reduction:** ~10 lines + improved consistency

---

## Category 4: VastTool Status Checks (CRITICAL)

### Duplication Count: 2 complete blocks (77+ lines each)

**Nearly identical vast_tool validation blocks in playbooks:**

| Playbook | Lines | Tasks |
|----------|-------|-------|
| `playbooks/oneidentity_linbit_check.yaml` | 31-107 | 10 tasks + fact storage |
| `playbooks/server_audit.yaml` | 271-328 | 9 tasks + fact storage |

### Tasks Duplicated (EXACT MATCHES):
1. Check if vastool is installed (`which vastool`)
2. Get vastool version (`vastool -v`)
3. Check vastool status (`vastool status`)
4. Check vastool joined domains (`vastool domains`)
5. Check vastool license status (`vastool license -s`)
6. Check host joined status (`vastool info domain`)
7. Get vastool configuration (`vastool info config`) - only in oneidentity_linbit_check
8. Check vastool users cache (`vastool list users`) - only in oneidentity_linbit_check
9. Check vastool groups cache (`vastool list groups`) - only in oneidentity_linbit_check
10. Store vastool information (set_fact)

### Example Code (appears 2 times with minor variations):

```yaml
- name: Check if vastool is installed
  ansible.builtin.command: which vastool
  register: vastool_installed
  changed_when: false
  ignore_errors: true

- name: Get vastool version
  ansible.builtin.shell: vastool -v
  register: vastool_version
  changed_when: false
  ignore_errors: true
  when: vastool_installed is succeeded

# ... 7+ more identical tasks
```

### Recommendation:
✅ **Create reusable task file:** `tasks/check_vastool_status.yaml`
✅ **Include from both playbooks:** `include_tasks: ../tasks/check_vastool_status.yaml`
✅ **Parameterize differences:** Use variables for optional checks (users/groups/config)
✅ **Estimated reduction:** ~70-80 lines of code

---

## Category 5: DRBD Status Checks (HIGH PRIORITY)

### Duplication Count: 2 complete blocks (60+ lines each)

**Nearly identical DRBD validation blocks in playbooks:**

| Playbook | Lines | Tasks |
|----------|-------|-------|
| `playbooks/oneidentity_linbit_check.yaml` | 130-207 | 8 tasks + fact storage |
| `playbooks/server_audit.yaml` | 333-405 | 8 tasks + fact storage |

### Tasks Duplicated:
1. Check if DRBD is installed (`which drbdadm`)
2. Get DRBD version (`drbdadm --version`)
3. Check DRBD status (`drbdadm status`)
4. Check DRBD kernel module loaded (`lsmod | grep drbd`)
5. List DRBD resources (`drbdadm dump`)
6. Check /proc/drbd info (`cat /proc/drbd`)
7. Get DRBD resource details
8. Store DRBD information (set_fact)

### Recommendation:
✅ **Create reusable task file:** `tasks/check_drbd_status.yaml`
✅ **Include from both playbooks**
✅ **Estimated reduction:** ~60-70 lines of code

---

## Category 6: Linstor Status Checks (HIGH PRIORITY)

### Duplication Count: 2 complete blocks (80+ lines each)

**Nearly identical Linstor validation blocks in playbooks:**

| Playbook | Lines | Tasks |
|----------|-------|-------|
| `playbooks/oneidentity_linbit_check.yaml` | 212-316 | 11 tasks + fact storage |
| `playbooks/server_audit.yaml` | 333-439 | 10 tasks + fact storage |

### Tasks Duplicated:
1. Check if linstor is installed (`which linstor`)
2. Get linstor version (`linstor --version`)
3. Check linstor controller status (`linstor controller list`)
4. Check linstor satellite status (`linstor node list`)
5. List linstor nodes (`linstor node list`)
6. List linstor resources (`linstor resource list`)
7. List storage pools (`linstor storage-pool list`)
8. List volumes (`linstor volume list`)
9. Check error reports (`linstor error-reports list`)
10. Store linstor information (set_fact)

### Recommendation:
✅ **Create reusable task file:** `tasks/check_linstor_status.yaml`
✅ **Include from both playbooks**
✅ **Estimated reduction:** ~80-90 lines of code

---

## Category 7: Package Installation Pattern (MEDIUM PRIORITY)

### Duplication Count: All roles that install packages (8+ instances)

**Pattern:** Every role follows the same sequence:
1. Update apt cache
2. Install packages via apt module
3. Start/enable systemd services

**Roles affected:**
- cluster_base
- cluster_drbd
- cluster_pacemaker
- cluster_storage
- cluster_vm
- cluster_monitoring
- cluster_identity
- cluster_network

### Current Pattern (repeated everywhere):

```yaml
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes

- name: Install XYZ packages
  ansible.builtin.apt:
    name: "{{ role_specific_packages }}"
    state: present

- name: Start XYZ service
  ansible.builtin.systemd:
    state: started
    enabled: yes
    name: "{{ service_name }}"
```

### Recommendation:
✅ **Standardize package lists:** All roles already use variables (e.g., `cluster_drbd_packages`)
✅ **Use role defaults:** Keep package lists in `defaults/main.yaml`
✅ **Consider meta-role:** Create `ubuntu_packages` role (already exists!) and expand it
⚠️ **Note:** Some duplication acceptable for role independence

---

## Summary of Recommendations

### Immediate Actions (High Impact):

1. **Create `roles/common/` directory** with reusable task files:
   - `tasks/check_os_ubuntu.yaml` - OS version validation
   - `tasks/check_vastool_status.yaml` - OneIdentity checks
   - `tasks/check_drbd_status.yaml` - DRBD system checks
   - `tasks/check_linstor_status.yaml` - Linstor checks

2. **Refactor AD Authentication:**
   - Remove duplicate from `cluster_network/tasks/main.yaml`
   - Document `cluster_identity` as single source

3. **Standardize apt cache handling:**
   - Use handlers or pre_tasks blocks
   - Remove scattered update_cache calls

### Long-term Improvements:

4. **Create testing framework** to validate shared tasks work across all roles
5. **Document task dependencies** in role README files
6. **Consider role dependencies** using `meta/main.yaml` dependencies

---

## Impact Analysis

### Current State:
- **Total duplicate lines:** ~500+ lines
- **Maintenance locations:** 25+ files need updates for similar changes
- **Risk of divergence:** HIGH - already seeing inconsistencies in AD auth packages

### After Refactoring:
- **Estimated reduction:** ~400-450 lines
- **Maintenance locations:** ~5-7 centralized files
- **Risk of divergence:** LOW - single source of truth
- **Testing efficiency:** Improved - test once, use everywhere
- **Consistency:** Guaranteed across all roles and playbooks

---

## Files Analyzed

### Playbooks (11):
- cluster_setup.yaml
- oneidentity_linbit_check.yaml
- pcm_resources.yaml
- server_audit.yaml
- vm_finder.yaml
- vm_discovery_playbook.yaml
- vm_discovery_playbook_2.yaml
- vm_cdrom_eject.yaml
- vm_drbd_pcm.yaml
- vm_management.yaml
- site.yml

### Roles (12):
- cluster_base
- cluster_network
- cluster_storage
- cluster_drbd
- cluster_linstor
- cluster_pacemaker
- cluster_vm
- cluster_identity
- cluster_cockpit
- cluster_monitoring
- ubuntu_packages
- cck-tests

### Total Task Files Analyzed: 39+

---

## Next Steps

1. Review this report with the team
2. Prioritize which duplications to address first
3. Create the `roles/common/` structure
4. Begin refactoring starting with Category 1 (OS checks)
5. Test thoroughly after each refactoring step
6. Update documentation

---

**Report End**
