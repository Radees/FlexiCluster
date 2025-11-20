# Contributing to EPM Infrastructure Management

Thank you for contributing to the EPM Infrastructure Management project (`Radees/epm-breadcrumbs`)! This document outlines the standards and conventions for maintaining consistency across the repository.

> **Repository**: This is a unified codebase combining the original epm-breadcrumbs and e-space repositories.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Naming Conventions](#naming-conventions)
- [Ansible Best Practices](#ansible-best-practices)
- [Git Workflow](#git-workflow)
- [Testing](#testing)

## Repository Structure

```
epm-breadcrumbs/
├── ansible/                        # Ansible infrastructure code
│   ├── playbooks/                  # Playbook files
│   ├── roles/                      # Ansible roles
│   ├── inventory/                  # Inventory files (production/staging)
│   ├── inventories/                # Alternative inventory structure
│   ├── files/                      # Static files, scripts, configs
│   ├── templates/                  # Jinja2 templates
│   ├── docs/                       # Cluster documentation
│   ├── ansible.cfg                 # Ansible configuration
│   ├── inventory.yaml              # Main inventory file
│   └── site.yml                    # Site-wide playbook
├── docs/                           # General documentation
│   ├── guides/                     # How-to guides and references
│   └── archive/                    # Archived/legacy files
├── README.md                       # Main project documentation
├── CONTRIBUTING.md                 # This file
└── LICENSE                         # License information
```

## Naming Conventions

### File Extensions

- **Ansible files**: Always use `.yaml` (NOT `.yml`)
- **Shell scripts**: Use `.sh` extension
- **Python scripts**: Use `.py` extension
- **Documentation**: Use `.md` extension

### Playbook Naming

- Use `snake_case` for all playbook names
- Use descriptive names that indicate the playbook's purpose
- Examples:
  - ✅ `server_audit.yaml`
  - ✅ `vm_discovery_playbook.yaml`
  - ✅ `pcm_resources.yaml`
  - ❌ `server-audit.yml`
  - ❌ `ServerAudit.yaml`

### Role Naming

- Use `snake_case` for role directory names
- Prefix cluster-related roles with `cluster_`
- Examples:
  - ✅ `cluster_base`
  - ✅ `cluster_drbd`
  - ✅ `ubuntu_packages`
  - ❌ `cluster-base`
  - ❌ `ClusterBase`

### Variable Naming

- Use `snake_case` for all variable names
- Use descriptive, meaningful names
- Examples:
  - ✅ `floating_ip`
  - ✅ `audit_output_dir`
  - ✅ `ansible_distribution`
  - ❌ `floatingIP`
  - ❌ `ip`

### Directory Naming

- Use lowercase with hyphens or underscores as appropriate
- Examples:
  - ✅ `group_vars`
  - ✅ `host_vars`
  - ✅ `original-txt-files`

## Ansible Best Practices

### Playbook Structure

1. **Header Comments**: Include descriptive header with purpose and usage
```yaml
---
# ============================================================================
# Playbook Name
# ============================================================================
# Description: Brief description
# Purpose: What it does
# Usage: How to run it
# ============================================================================
```

2. **Use Fully Qualified Collection Names (FQCNs)**
```yaml
# ✅ Good
- name: Copy file
  ansible.builtin.copy:
    src: file.txt
    dest: /tmp/file.txt

# ❌ Bad
- name: Copy file
  copy:
    src: file.txt
    dest: /tmp/file.txt
```

3. **Tags**: Add tags for selective execution
```yaml
- name: Task name
  tags: [network, always]
  ansible.builtin.command: ip addr
```

4. **Error Handling**: Use `block`/`rescue`/`always` for error handling
```yaml
- name: Task with error handling
  block:
    - name: Main task
      ansible.builtin.command: some_command
  rescue:
    - name: Handle error
      ansible.builtin.debug:
        msg: "Task failed"
  always:
    - name: Cleanup
      ansible.builtin.file:
        path: /tmp/cleanup
        state: absent
```

### Role Structure

Roles should follow this standard structure:

```
role_name/
├── README.md              # Role documentation
├── defaults/
│   └── main.yaml         # Default variables
├── files/                # Static files
├── handlers/
│   └── main.yaml         # Handlers
├── meta/
│   └── main.yaml         # Role metadata
├── tasks/
│   ├── main.yaml         # Main task file (includes other tasks)
│   ├── pre_checks.yaml   # Pre-installation checks
│   ├── install.yaml      # Installation tasks
│   └── configure.yaml    # Configuration tasks
├── templates/            # Jinja2 templates
├── tests/
│   ├── inventory         # Test inventory
│   └── test.yaml         # Test playbook
└── vars/
    └── main.yaml         # Role variables
```

### Task Organization

- **One logical task per file** when using `include_tasks`
- Group related tasks together
- Use descriptive task names
- Example `main.yaml`:
```yaml
---
- name: Include pre-installation checks
  ansible.builtin.include_tasks: pre_checks.yaml
  tags: [pre_checks]

- name: Include package installation
  ansible.builtin.include_tasks: install.yaml
  tags: [install]

- name: Include configuration
  ansible.builtin.include_tasks: configure.yaml
  tags: [configure]
```

### Inventory Organization

- Use separate directories for different environments (`production/`, `staging/`)
- Use `group_vars/` for group-specific variables
- Use `host_vars/` for host-specific variables
- Keep sensitive data in Ansible Vault

## Git Workflow

### Branching

- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `bugfix/*` - Bug fix branches

### Commit Messages

Use clear, descriptive commit messages:

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

- Bullet points are okay
- Use present tense ("Add feature" not "Added feature")
- Reference issues: "Fixes #123"
```

### Pull Requests

- Update documentation to reflect changes
- Test changes in staging environment first
- Request review from at least one team member
- Ensure CI/CD checks pass

## Testing

### Before Committing

1. **Syntax Check**:
```bash
ansible-playbook --syntax-check playbook.yaml
```

2. **Dry Run**:
```bash
ansible-playbook --check playbook.yaml
```

3. **Linting**:
```bash
ansible-lint playbook.yaml
```

### Testing Playbooks

- Test in staging environment first
- Use `--check` mode for dry runs
- Use `--diff` to see changes
- Use `-l` to limit to specific hosts
- Use tags to test specific sections

### Testing Roles

- Include test playbook in `tests/test.yaml`
- Document test scenarios in role README
- Test with different variable configurations

## Documentation

### Playbook Documentation

Every playbook should include:
- Purpose and description
- Required variables
- Optional variables with defaults
- Usage examples
- Available tags
- Output/reports location

### Role Documentation

Every role should have a `README.md` with:
- Role description
- Requirements
- Role variables
- Dependencies
- Example playbook usage
- License

### Code Comments

- Comment complex logic
- Explain why, not what
- Keep comments up to date
- Use YAML comments (`#`)

## Code Review Checklist

- [ ] Follows naming conventions
- [ ] Uses `.yaml` extension
- [ ] Includes FQCNs for modules
- [ ] Has appropriate tags
- [ ] Includes error handling
- [ ] Documentation updated
- [ ] Tested in staging
- [ ] No sensitive data in commits
- [ ] Follows role structure
- [ ] Clear commit messages

## Questions?

If you have questions about these guidelines, please:
1. Check existing code for examples
2. Review the Ansible documentation
3. Ask the team for clarification

## License

By contributing, you agree that your contributions will be licensed under the project's license.
