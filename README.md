# PythonDev (pythondev)

<!-- markdownlint-disable MD033 MD041 -->
<img src="https://kura.pro/pythondev/images/logos/pythondev.webp"
alt="PythonDev logo" height="66" align="right" />
<!-- markdownlint-enable MD033 MD041 -->

An opinionated, secure, Alpine-based Docker container providing a complete Python development environment with NeoVim configuration. Engineered for safety, efficiency, and developer productivity. **This is not an official Python project** and is not affiliated with or supported by the Python Software Foundation.

<!-- markdownlint-disable MD033 MD041 -->
<center>
<!-- markdownlint-enable MD033 MD041 -->

[![Made with Alpine Linux][alpine-badge]][08] [![Docker][docker-badge]][03] [![Python][python-badge]][01] [![NeoVim][neovim-badge]][04] [![Security][security-badge]][06] [![Build Status][build-badge]][07]

• [Features](#key-features) • [Prerequisites](#prerequisites) • [Installation](#installation) • [Configuration](#configuration) • [Security](#security)

<!-- markdownlint-disable MD033 MD041 -->
</center>
<!-- markdownlint-enable MD033 MD041 -->

## Disclaimer

This is an opinionated development environment that reflects specific preferences for tooling, configuration, and workflow. It is:

- Not an official Python project
- Not affiliated with or supported by the Python Software Foundation or its contributors
- Not intended to be a one-size-fits-all solution
- Maintained independently and based on [docker hub python][02] and other open-source projects
- Provided as-is with no warranties (see [License](#license))

## Overview

**PythonDev** is a containerized Python development environment that prioritizes security, performance, and developer convenience. Built on Alpine Linux 3.21.3 for a minimal footprint, it includes a pre-configured NeoVim setup with Python-specific tooling, intelligent code completion, and Git integration.

## Key Features

- **Security Standards**
  - OCI container verification and trust
  - Base image digest verification
  - Content trust enforcement
  - SECCOMP profile implementation
  - Enhanced security labels
  - Regular vulnerability scanning

- **Secure by Design**
  - Alpine Linux 3.21.3 base with minimal attack surface
  - Non-root user operation (UID 1000)
  - Comprehensive security hardening
  - PAM security implementation
  - Container isolation and resource limits
  - Core dump protection
  - SUID/SGID binary removal
  - System file immutability

- **Python Development Tools**
  - Python 3.12.0 built from source
  - UV package installer for faster dependency management
  - Virtual environment configuration
  - Optimized Python build
  - Complete stdlib verification
  - Path isolation and environment control

- **Enhanced Development Experience**
  - NeoVim with LazyVim configuration
  - Intelligent code completion
  - Syntax highlighting
  - Git integration
  - Terminal integration
  - Fuzzy finding

## Prerequisites

- Docker 24.0 or newer
- Docker Compose V2
- Minimum 4GB RAM (8GB recommended)
- At least 10GB free disk space
- Git 2.40 or newer
- Terminal with SSH support

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/sebastienrousseau/pythondev.git
   cd pythondev
   ```

2. **Configure the environment (optional):**
   Default values are provided, but you can customize in `.env`:

   ```bash
   LANG=en_US.UTF-8
   NAME=pythondev-container
   OS=alpine
   SHELL=/bin/bash
   TZ=UTC
   VERSION=latest
   PYTHON_VERSION=3.12.0
   ```

3. **Build and start the development environment:**

   ```bash
   docker-compose up --build -d
   ```

4. **Access the container:**

   ```bash
   docker exec -it pythondev bash
   ```

## Configuration

### Environment Variables

The container uses pre-configured environment variables with sensible defaults:

```bash
DOCKER_CONTENT_TRUST=1       # Enable Docker content trust
SECCOMP_PROFILE=default      # Security computing mode profile
PYTHONHOME=/opt/venv         # Python installation directory
PYTHONPATH=/opt/venv/lib/python3.12/site-packages
PYTHONDONTWRITEBYTECODE=1    # Prevent Python from writing pyc files
PYTHONUNBUFFERED=1           # Prevent Python from buffering stdout/stderr
```

### Docker Configuration

Example `docker-compose.yml`:

```yaml
services:
  pythondev:
    image: pythondev:latest
    container_name: pythondev
    build:
      context: .
      args:
        PYTHON_VERSION: "3.12.0"
    env_file:
      - .env
    user: "1000:1000"
    working_dir: "/home/pythondev/code"
    stdin_open: true
    tty: true
    healthcheck:
      test: ["CMD", "python", "--version"]
      interval: 300s
      timeout: 10s
      retries: 3
      start_period: 5s
    command: ["/bin/bash", "--login"]
```

## Security

The container implements multiple layers of security:

- Non-root user operation (UID 1000)
- Minimal base image (Alpine 3.21.3)
- Content trust verification
- SECCOMP profile implementation
- Resource limitations
- Regular security updates
- System hardening
- Core dump protection
- SUID/SGID removal
- File system restrictions
- Process isolation
- User access control
- Enhanced healthchecks

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

[alpine-badge]: https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white
[docker-badge]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[python-badge]: https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white
[neovim-badge]: https://img.shields.io/badge/NeoVim-57A143?style=for-the-badge&logo=neovim&logoColor=white
[security-badge]: https://img.shields.io/badge/Security-Hardened-success?style=for-the-badge
[build-badge]: https://img.shields.io/badge/Build-Passing-success?style=for-the-badge

[01]: https://www.python.org
[02]: https://hub.docker.com/_/python
[03]: https://www.docker.com
[04]: https://neovim.io
[06]: #security
[07]: https://github.com/sebastienrousseau/pythondev/actions
[08]: https://alpinelinux.org
