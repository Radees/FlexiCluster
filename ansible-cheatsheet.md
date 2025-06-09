# Ansible Variables and Host Facts Cheat Sheet

## Ansible Built-in Variables

| Variable | Description |
|----------|-------------|
| `hostvars` | Dictionary/map of all hosts and their variables |
| `inventory_hostname` | Name of the current host as defined in inventory |
| `inventory_hostname_short` | Short name of the host (before first period) |
| `group_names` | List of groups the current host is part of |
| `groups` | Dictionary/map of all groups and their hosts |
| `playbook_dir` | Directory of the playbook being executed |
| `ansible_play_hosts` | List of inventory hosts in the current play |
| `ansible_play_batch` | List of hosts in the current batch |
| `ansible_version` | Dictionary with Ansible version info |
| `ansible_check_mode` | Boolean indicating if check mode is on |
| `ansible_verbosity` | Verbosity level (0-4) |
| `ansible_host` | The IP/host to connect to |
| `ansible_user` | The user to connect as |
| `ansible_connection` | The connection method (ssh, local, etc.) |

## Commonly Used Host Facts (ansible_facts)

| Fact | Description |
|------|-------------|
| `ansible_facts['distribution']` | OS distribution (Ubuntu, CentOS, etc.) |
| `ansible_facts['distribution_version']` | OS version |
| `ansible_facts['distribution_major_version']` | OS major version |
| `ansible_facts['os_family']` | OS family (Debian, RedHat, etc.) |
| `ansible_facts['architecture']` | System architecture (x86_64, etc.) |
| `ansible_facts['kernel']` | Kernel version |
| `ansible_facts['hostname']` | System hostname |
| `ansible_facts['fqdn']` | Fully qualified domain name |
| `ansible_facts['default_ipv4']['address']` | Default IPv4 address |
| `ansible_facts['default_ipv6']['address']` | Default IPv6 address |
| `ansible_facts['interfaces']` | List of network interfaces |
| `ansible_facts['devices']` | Dictionary of devices/disks |
| `ansible_facts['mounts']` | List of mounted filesystems |
| `ansible_facts['memtotal_mb']` | Total memory in MB |
| `ansible_facts['memfree_mb']` | Free memory in MB |
| `ansible_facts['processor_count']` | Number of processors |
| `ansible_facts['processor_cores']` | Number of cores per processor |
| `ansible_facts['processor_vcpus']` | Number of virtual CPUs |
| `ansible_facts['python']['version']['major']` | Python major version |
| `ansible_facts['python']['version']['minor']` | Python minor version |
| `ansible_facts['selinux']['status']` | SELinux status |

## Variable Precedence (from lowest to highest)

1. Role defaults
2. Inventory vars
3. Inventory group_vars
4. Inventory host_vars
5. Playbook group_vars
6. Playbook host_vars
7. Host facts / gathered facts
8. Play vars
9. Play vars_prompt
10. Play vars_files
11. Role and include vars
12. Block vars
13. Task vars
14. Extra vars (command line variables)

## Accessing Variables

```yaml
# Simple variable
{{ variable_name }}

# Dictionary/map element
{{ dictionary_name['key'] }}
{{ dictionary_name.key }}

# List element
{{ list_name[0] }}

# Host variable for specific host
{{ hostvars['hostname']['variable_name'] }}
```

## Variable Registration

```yaml
- name: Get command output
  command: uptime
  register: result

- name: Use registered variable
  debug:
    msg: "Uptime is {{ result.stdout }}"
```

## Common Ansible-Console Commands

```
# List all available hosts
list

# Connect to specific host or group
cd web_servers

# Show host facts
setup

# Show facts for specific host
setup hostname

# Run ad-hoc command
command uptime

# Include tasks or roles
include_tasks file=tasks.yml
include_role name=role_name

# Run a playbook
!ansible-playbook playbook.yml
playbook /path/to/playbook.yml
```