# EPM Breadcrumbs

A collection of scripts, playbooks, and documentation for Enterprise Package Management (EPM) infrastructure.

## Repository Contents

### Ansible Infrastructure (`ansible/`)

**Fully refactored Ansible structure** with best practices for managing cluster infrastructure:

- **Playbooks**: Server auditing, VM management, PCM/Pacemaker configuration
- **Roles**: Ubuntu package installation role
- **Inventory**: Production and staging environments with group variables
- **Templates**: Report generation templates
- **Documentation**: Cheatsheets and guides

👉 **[See Ansible README](ansible/README.md)** for complete documentation

### Scripts

- **DRBD/LVM Testing**
  - `drbd-lvm-test-suite.sh` - Comprehensive DRBD test suite
  - `drbd-lvm-thin-tests.sh` - DRBD thin provisioning tests

- **Pacemaker/Cluster Testing**
  - `pacemaker-cluster-tests.sh` - Pacemaker cluster test suite

- **Utilities**
  - `run-playbook-script.sh` - Ansible playbook execution wrapper
  - `md-to-atlassian-converter.py` - Convert Markdown to Atlassian wiki format

### Documentation

- `network-documentation.md` - Network configuration documentation
- `linux-cluster-testing.md` - Linux cluster testing guide
- `linux-cluster-testing-adf.json` - Azure DevOps pipeline definition
- `readme.md` - Additional documentation

### Configuration Files

Legacy Ansible files (now refactored into `ansible/` directory):
- Various `.txt` files with Ansible content (superseded by new structure)

### KVM/Cloud-Init Files

Files for KVM Ubuntu cloud image management:
- `kvm-ubuntu-cloudimage-*.txt` - Scripts and configurations for cloud-init

## Quick Start

### Using Ansible

```bash
cd ansible/

# Run server audit
ansible-playbook playbooks/server_audit.yaml

# Find VM host
ansible-playbook playbooks/vm_finder.yaml -e "vm_name=myvm"

# Configure PCM resources
ansible-playbook playbooks/pcm_resources.yaml
```

See [ansible/README.md](ansible/README.md) for detailed usage.

### Running Test Suites

```bash
# DRBD tests
./drbd-lvm-test-suite.sh

# Pacemaker tests
./pacemaker-cluster-tests.sh
```

## Repository Structure

```
epm-breadcrumbs/
├── ansible/                              # Refactored Ansible infrastructure
│   ├── playbooks/                        # Ansible playbooks (.yaml)
│   ├── roles/                            # Ansible roles
│   ├── inventory/                        # Environment inventories
│   ├── templates/                        # Jinja2 templates
│   └── docs/                             # Ansible documentation
├── *.sh                                  # Shell scripts for testing
├── *.py                                  # Python utilities
├── *.md                                  # Documentation files
└── ansible-*.txt                         # Legacy files (see ansible/ for refactored versions)
```

## What's New - Ansible Refactoring

✅ **Proper structure**: Organized playbooks, roles, inventory, and templates
✅ **YAML format**: All playbooks use `.yaml` extension (not `.txt`)
✅ **Best practices**: FQCNs, tags, error handling, idempotency
✅ **Complete playbooks**: All fragments converted to standalone playbooks
✅ **Role-based**: Ubuntu package installation as reusable role
✅ **Environment separation**: Production and staging inventories
✅ **Templates**: Report generation with Jinja2 templates
✅ **Documentation**: Comprehensive README and usage examples

## Key Features

### Server Auditing
- Network configuration checks
- NTP synchronization status
- DNS configuration and testing
- Authentication (SSSD, LDAP) checks
- User and group membership
- KVM virtual machine inventory
- OneIdentity vastool status
- LINBIT Storage (DRBD/linstor) checks

### Cluster Management
- VM host discovery across cluster
- PCM/Pacemaker resource configuration
- Floating IP management
- Service resource grouping

### Testing
- DRBD resource testing
- LVM integration tests
- Pacemaker cluster functionality tests

## Contributing

When adding new content:
1. Follow the established directory structure
2. Use `.yaml` for Ansible files
3. Add documentation for new features
4. Test in staging before production

## License

See individual files for license information.

## Support

- **Ansible issues**: Check [ansible/README.md](ansible/README.md)
- **Script issues**: Review script headers for usage
- **General questions**: Check documentation in repository root
