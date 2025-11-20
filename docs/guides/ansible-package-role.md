# Ubuntu Package Installation Role

This Ansible role installs packages from a file list on Ubuntu servers. The role is structured following Ansible best practices and provides flexibility for different package installation needs.

## Role Structure

```bash
ubuntu_packages/
├── defaults/
│   └── main.yml
├── files/
│   └── package_list.txt
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   ├── main.yml
│   ├── pre_checks.yml
│   └── install_packages.yml
├── templates/
│   └── apt.conf.j2
├── vars/
│   └── main.yml
└── README.md
```

## Implementation Details

### defaults/main.yml
```yaml
---
# Default variables
ubuntu_packages_file: "package_list.txt"  # Default file containing package list
ubuntu_packages_list: []                  # Alternative: specify packages as a list in variables
ubuntu_packages_state: present            # Package state (present, latest, absent)
ubuntu_packages_update_cache: yes         # Update apt cache before installation
ubuntu_packages_cache_valid_time: 3600    # Cache validity time in seconds (1 hour)
ubuntu_packages_autoremove: yes           # Run apt autoremove after installation
ubuntu_packages_autoclean: yes            # Run apt autoclean after installation
ubuntu_packages_timeout: 60               # Installation timeout in seconds
ubuntu_packages_retry_count: 3            # Number of retries on failure
ubuntu_packages_retry_delay: 5            # Delay between retries in seconds
ubuntu_packages_parallel_jobs: 2          # Number of parallel jobs for apt
ubuntu_packages_custom_apt_config: no     # Whether to use custom apt.conf
```

### files/package_list.txt
```
# Core utilities
htop
tmux
vim
curl
wget
unzip

# Monitoring tools
iotop
iftop
sysstat

# Development tools
build-essential
git
python3-pip

# Add more packages as needed, one per line
# Lines starting with # are ignored
```

### handlers/main.yml
```yaml
---
# Handlers for package installation
- name: restart required services
  ansible.builtin.service:
    name: "{{ item }}"
    state: restarted
  loop: "{{ ubuntu_packages_services_to_restart }}"
  when: ubuntu_packages_services_to_restart is defined
```

### tasks/main.yml
```yaml
---
# Main tasks file for ubuntu_packages role

- name: Include OS-specific variables
  ansible.builtin.include_vars: "{{ item }}"
  with_first_found:
    - "{{ ansible_distribution | lower }}-{{ ansible_distribution_version }}.yml"
    - "{{ ansible_distribution | lower }}-{{ ansible_distribution_major_version }}.yml"
    - "{{ ansible_distribution | lower }}.yml"
    - "{{ ansible_os_family | lower }}.yml"
    - "default.yml"
  ignore_errors: true

- name: Check if running on Ubuntu
  ansible.builtin.assert:
    that:
      - ansible_distribution == "Ubuntu"
    fail_msg: "This role is designed for Ubuntu systems only"
    success_msg: "Running on supported Ubuntu system"

- name: Include pre-installation checks
  ansible.builtin.include_tasks: pre_checks.yml

- name: Include package installation tasks
  ansible.builtin.include_tasks: install_packages.yml
```

### tasks/pre_checks.yml
```yaml
---
# Pre-installation checks

- name: Ensure apt is available
  ansible.builtin.stat:
    path: /usr/bin/apt
  register: apt_available

- name: Check apt availability
  ansible.builtin.assert:
    that:
      - apt_available.stat.exists
    fail_msg: "apt package manager not found"
    success_msg: "apt package manager is available"

- name: Configure custom apt settings if enabled
  ansible.builtin.template:
    src: apt.conf.j2
    dest: /etc/apt/apt.conf.d/99custom
    owner: root
    group: root
    mode: '0644'
  when: ubuntu_packages_custom_apt_config | bool

- name: Update apt cache
  ansible.builtin.apt:
    update_cache: yes
    cache_valid_time: "{{ ubuntu_packages_cache_valid_time }}"
  register: apt_update
  until: apt_update is success
  retries: "{{ ubuntu_packages_retry_count }}"
  delay: "{{ ubuntu_packages_retry_delay }}"
```

### tasks/install_packages.yml
```yaml
---
# Package installation tasks

- name: Read package list from file if file is specified
  ansible.builtin.slurp:
    src: "{{ ubuntu_packages_file }}"
  register: package_file_content
  delegate_to: localhost
  when: 
    - ubuntu_packages_list | length == 0
    - ubuntu_packages_file is defined
    - ubuntu_packages_file != ""
  ignore_errors: true

- name: Parse package list from file
  ansible.builtin.set_fact:
    parsed_packages: "{{ (package_file_content['content'] | b64decode).split('\n') | 
                         select('match', '^[^#].*[a-zA-Z0-9]') | list }}"
  when: 
    - ubuntu_packages_list | length == 0
    - package_file_content is defined
    - package_file_content.content is defined

- name: Set final package list
  ansible.builtin.set_fact:
    final_packages: "{{ ubuntu_packages_list if ubuntu_packages_list | length > 0 else parsed_packages | default([]) }}"

- name: Display packages to be installed
  ansible.builtin.debug:
    msg: "Packages to be installed: {{ final_packages | join(', ') }}"
  when: final_packages | length > 0

- name: Install packages from the list
  ansible.builtin.apt:
    name: "{{ final_packages }}"
    state: "{{ ubuntu_packages_state }}"
    update_cache: "{{ ubuntu_packages_update_cache }}"
    cache_valid_time: "{{ ubuntu_packages_cache_valid_time }}"
  register: package_install
  until: package_install is success
  retries: "{{ ubuntu_packages_retry_count }}"
  delay: "{{ ubuntu_packages_retry_delay }}"
  async: "{{ ubuntu_packages_timeout }}"
  poll: 5
  when: final_packages | length > 0
  notify: restart required services

- name: Clean up package cache if configured
  ansible.builtin.apt:
    autoclean: "{{ ubuntu_packages_autoclean }}"
    autoremove: "{{ ubuntu_packages_autoremove }}"
  when: ubuntu_packages_autoclean | bool or ubuntu_packages_autoremove | bool
```

### templates/apt.conf.j2
```
// Custom APT configuration generated by Ansible
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::Get::Assume-Yes "true";
APT::Get::Fix-Missing "true";
Acquire::Retries "3";
Acquire::https::Timeout "30";
Acquire::http::Timeout "30";
Acquire::Queue-Mode "host";
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
Acquire::Languages "none";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "7";
Acquire::MaxParallelJobs "{{ ubuntu_packages_parallel_jobs }}";
```

### meta/main.yml
```yaml
---
galaxy_info:
  role_name: ubuntu_packages
  author: Your Name
  description: Role to install packages from a file list on Ubuntu servers
  company: Example Company
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
        - bionic
  galaxy_tags:
    - ubuntu
    - packages
    - system
    - apt
dependencies: []
```

## Example Usage

### Example Playbook (Using Default Package List File)
```yaml
---
- name: Install packages on Ubuntu servers
  hosts: ubuntu_servers
  become: yes
  roles:
    - role: ubuntu_packages
```

### Example Playbook (Using Custom Package List File)
```yaml
---
- name: Install packages on Ubuntu servers
  hosts: ubuntu_servers
  become: yes
  roles:
    - role: ubuntu_packages
      vars:
        ubuntu_packages_file: "{{ playbook_dir }}/files/custom_package_list.txt"
```

### Example Playbook (Using Package List in Variables)
```yaml
---
- name: Install packages on Ubuntu servers
  hosts: ubuntu_servers
  become: yes
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

### Example Using ansible-console
```
ansible ubuntu_servers -m include_role -a "name=ubuntu_packages"
ansible ubuntu_servers -m include_role -a "name=ubuntu_packages vars={'ubuntu_packages_list':['nginx','apache2']}"
```