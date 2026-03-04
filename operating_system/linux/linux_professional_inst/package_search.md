# Package Search Commands

## DNF / YUM (Red Hat, Fedora, CentOS)

```bash
# Search for a package by name or description
dnf search <package_name>

# Get detailed info about a package
dnf info <package_name>

# List all available packages
dnf list available

# List installed packages
dnf list installed

# Find which package provides a specific file
dnf provides <file_path>
```

## APT (Debian, Ubuntu)

```bash
# Search for a package by name or description
apt search <package_name>

# Show detailed info about a package
apt show <package_name>

# List all available packages
apt list

# List installed packages
apt list --installed

# Find which package provides a specific file
apt-file search <file_path>
```

## Zypper (openSUSE)

```bash
# Search for a package
zypper search <package_name>

# Show package info
zypper info <package_name>

# Find which package provides a file
zypper search --provides <file_path>
```

## RPM (Query installed packages)

```bash
# Search installed packages
rpm -qa | grep <package_name>

# Get info about an installed package
rpm -qi <package_name>

# Find which installed package owns a file
rpm -qf <file_path>

# List files provided by an installed package
rpm -ql <package_name>
```

## DPKG (Query installed packages on Debian-based)

```bash
# Search installed packages
dpkg -l | grep <package_name>

# Get info about an installed package
dpkg -s <package_name>

# Find which installed package owns a file
dpkg -S <file_path>

# List files provided by an installed package
dpkg -L <package_name>
```
