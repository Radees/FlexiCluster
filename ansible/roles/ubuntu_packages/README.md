# Ubuntu Packages Role

This Ansible role installs packages from a file list on Ubuntu servers. The role is structured following Ansible best practices and provides flexibility for different package installation needs.

## Requirements

- Ansible 2.9 or higher
- Ubuntu 18.04 (Bionic) or later
- sudo privileges on target hosts

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yaml`):

```yaml
# Package source configuration
ubuntu_packages_file: "package_list.txt"
ubuntu_packages_list: []

# Package state and behavior
ubuntu_packages_state: present
ubuntu_packages_update_cache: true
ubuntu_packages_cache_valid_time: 3600

# Cleanup options
ubuntu_packages_autoremove: true
ubuntu_packages_autoclean: true

# Performance and reliability
ubuntu_packages_timeout: 300
ubuntu_packages_retry_count: 3
ubuntu_packages_retry_delay: 5
ubuntu_packages_parallel_jobs: 2

# Advanced configuration
ubuntu_packages_custom_apt_config: false
ubuntu_packages_services_to_restart: []
```

## Dependencies

None.

## Example Playbook

### Using Default Package List File

```yaml
---
- name: Install packages on Ubuntu servers
  hosts: ubuntu_servers
  become: true
  roles:
    - role: ubuntu_packages
```

### Using Custom Package List File

```yaml
---
- name: Install packages on Ubuntu servers
  hosts: ubuntu_servers
  become: true
  roles:
    - role: ubuntu_packages
      vars:
        ubuntu_packages_file: "custom_package_list.txt"
```

### Using Package List in Variables

```yaml
---
- name: Install packages on Ubuntu servers
  hosts: ubuntu_servers
  become: true
  roles:
    - role: ubuntu_packages
      vars:
        ubuntu_packages_list:
          - nginx
          - postgresql
          - redis-server
        ubuntu_packages_state: latest
        ubuntu_packages_services_to_restart:
          - nginx
          - postgresql
```

## Package List File Format

Create a text file with one package name per line:

```
# Comments start with #
htop
vim
curl
wget
```

## License

MIT

## Author Information

EPM Team - Enterprise Package Management
