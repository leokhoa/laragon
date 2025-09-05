# Laragon - Windows Development Environment

Laragon is a portable, isolated Windows development environment for PHP, Node.js, and Python. This repository contains the distribution files and configuration templates for Laragon.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Critical Limitations

**WINDOWS-ONLY ENVIRONMENT**: Laragon is exclusively a Windows GUI application. The main executable (laragon.exe) is a Windows PE32+ binary that cannot run on Linux or macOS. Development and testing of the actual Laragon environment requires Windows.

**NO BUILD PROCESS**: This repository contains pre-built binaries and configuration files. There is no source code compilation, build system, or CI/CD pipeline.

**NO AUTOMATED TESTS**: This is a packaged application distribution, not a development project with test suites.

## Working Effectively on Linux/macOS

While you cannot run Laragon itself, you can:

### Repository Structure Exploration
- View and understand the file structure: `ls -la /path/to/laragon`
- Examine configuration files: `find . -name "*.ini" -o -name "*.conf"`
- Check included software versions: `grep -r "Version=" usr/laragon.ini`
- List bundled tools: `ls -la bin/`

### Configuration Management
- View main configuration: `cat usr/laragon.ini`
- Check site templates: `cat usr/sites.conf`
- Examine Procfile format: `cat usr/Procfile`
- Review user customization: `cat usr/user.cmd`

### Documentation Tasks
- Edit README.md and documentation files
- Update configuration templates
- Modify default project templates in www/
- Update site configuration examples

## Laragon Architecture

### Core Components
- **laragon.exe**: Main Windows GUI application (5.3MB PE32+ executable)
- **bin/**: Bundled software packages
  - PHP 5.4.9 (Windows VC9 x86)
  - MySQL 5.1.72 (Windows 32-bit)
  - Nginx 1.14.0
  - Apache (configurable)
  - Composer (PHP dependency manager)
  - HeidiSQL (database management GUI)
  - Cmder (terminal emulator)
  - Notepad++ (text editor)
  - Sendmail (mail handling)

### Configuration Files
- **usr/laragon.ini**: Main configuration (service versions, preferences)
- **usr/sites.conf**: Project template definitions
- **usr/Procfile**: Custom service definitions
- **usr/user.cmd**: User startup customizations
- **etc/**: Service-specific configurations (Apache, Nginx, PHP)

### Directory Structure
```
laragon/
├── laragon.exe              # Main Windows GUI application
├── bin/                     # Bundled software (PHP, MySQL, Nginx, etc.)
├── etc/                     # Configuration files for services
├── usr/                     # User configurations and templates
├── www/                     # Default web root directory
├── README.md               # Project documentation
├── CHANGELOG.md            # Version history
└── SECURITY.md             # Security policy
```

## Key Features
- **Portable**: Entire environment can be moved between Windows machines
- **Auto-configuration**: Services are automatically configured when started
- **Pretty URLs**: Uses `.test` domains instead of localhost
- **Multi-version support**: Can switch between different PHP/MySQL versions
- **Project templates**: Built-in templates for WordPress, Laravel, Symfony

## Common Tasks

### Examining Service Versions
```bash
# Check configured versions
grep "Version=" usr/laragon.ini

# List available software in bin directory
ls bin/
```

### Configuration File Management
```bash
# View main configuration
cat usr/laragon.ini

# Check site template definitions
cat usr/sites.conf

# Examine user customization file
cat usr/user.cmd
```

### Project Template Analysis
```bash
# Check available project types
grep "^[A-Za-z]" usr/sites.conf | grep "="

# View default web page
cat www/index.php
```

### Structure Exploration
```bash
# Repository root contents
ls -la

# Find all configuration files
find . -name "*.ini" -o -name "*.conf" | head -10

# Check documentation files
find . -name "*.md"
```

## Validation on Windows

**Note**: These steps can only be performed on a Windows machine with Laragon installed:

### Basic Functionality Testing
1. Start Laragon GUI application
2. Verify all services start (Apache/Nginx, MySQL, PHP)
3. Access http://localhost to see default page
4. Create a test project using quick app creation
5. Verify pretty URLs work (e.g., http://testapp.test)

### Configuration Validation
1. Modify usr/laragon.ini settings
2. Restart Laragon to apply changes
3. Verify service versions match configuration
4. Test custom Procfile entries
5. Validate user.cmd customizations

## File Editing Guidelines

### Safe to Edit
- **Documentation**: README.md, CHANGELOG.md, SECURITY.md
- **Configuration templates**: usr/laragon.ini, usr/sites.conf
- **Default web content**: www/index.php
- **User scripts**: usr/user.cmd, usr/Procfile

### Do Not Modify
- **Binary files**: laragon.exe, all files in bin/
- **Service configurations**: etc/ files (unless creating templates)
- **Git ignored items**: See .gitignore for excluded files

## Development Workflow

### For Configuration Changes
1. Edit configuration files using text editors
2. Validate syntax if applicable (e.g., INI format for laragon.ini)
3. Test changes on Windows Laragon installation
4. Document changes in comments or README

### For Documentation Updates
1. Edit Markdown files directly
2. Ensure proper formatting and links
3. Validate Markdown syntax
4. No special testing required

## Repository Maintenance

### Adding New Project Templates
1. Edit usr/sites.conf
2. Follow existing format: `ProjectName=installation_command`
3. Test template on Windows Laragon installation
4. Document new template in README if needed

### Configuration Updates
1. Modify relevant .ini or .conf files
2. Ensure Windows compatibility
3. Test with actual Laragon installation
4. Update documentation if behavior changes

## Common File Locations

### Frequently Referenced Files
```bash
# Main configuration
usr/laragon.ini

# Project templates  
usr/sites.conf

# Default web page
www/index.php

# User customization
usr/user.cmd

# Main documentation
README.md
```

### Configuration Paths
```bash
# Apache configuration
etc/apache2/

# Nginx configuration  
etc/nginx/

# PHP configuration
etc/php/

# SSL certificates
etc/ssl/
```

This repository serves as the distribution package for Laragon. All development and testing of the actual development environment functionality must be done on Windows machines with Laragon installed.