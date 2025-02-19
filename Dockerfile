###############################################################################
# Dockerfile for a Python Development Environment on Alpine Linux (3.21.3)
# with Python 3.12 built from source. Hardening steps included.
###############################################################################
FROM alpine:3.21.3

###############################################################################
# Alpine public key for signature verification (Content Trust)
###############################################################################
ARG ALPINE_FINGERPRINT="alpine-devel@lists.alpinelinux.org-4a6a0840.rsa.pub"
RUN wget -P /etc/apk/keys/ "https://alpinelinux.org/keys/${ALPINE_FINGERPRINT}"

###############################################################################
# Container metadata labels (including 2025 updates)
###############################################################################
LABEL org.opencontainers.image.source="https://github.com/python/dev" \
    maintainer="Python Developer" \
    io.container.seccomp="default" \
    io.container.security.capabilities="drop=all,add=net_bind_service" \
    org.opencontainers.image.created="2025-02-18" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.base.digest="sha256:$(wget -qO- https://hub.docker.com/v2/repositories/alpine/tags/3.21.3 | jq -r '.images[0].digest')"

###############################################################################
# Define build arguments (with sensible defaults for placeholders)
###############################################################################
ARG ARCH="$(apk --print-arch)"
ARG LANG="en_US.UTF-8"
ARG NAME="pythondev-container"
ARG OS="alpine"
ARG SHELL="/bin/bash"
ARG TZ="UTC"
ARG VERSION="latest"
ARG PYTHON_VERSION="3.12.0"

###############################################################################
# Set environment variables
###############################################################################
ENV ARCH=${ARCH} \
    DOCKER_CONTENT_TRUST=1 \
    LANG=${LANG} \
    NAME=${NAME} \
    OS=${OS} \
    PATH="/opt/venv/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONHOME="/opt/venv" \
    PYTHONPATH="/opt/venv/lib/python3.12/site-packages" \
    PYTHONUNBUFFERED=1 \
    PYTHON_VERSION=${PYTHON_VERSION} \
    SECCOMP_PROFILE="default" \
    SHELL=${SHELL} \
    TZ=${TZ} \
    USERHOME="/home/pythondev" \
    USERNAME="pythondev" \
    VERSION=${VERSION}

###############################################################################
# Create the 'pythondev' user and home directory
###############################################################################
RUN adduser -D -h "$USERHOME" -u 1000 "$USERNAME" \
    && mkdir -p "$USERHOME/code" \
    && chown -R "$USERNAME":"$USERNAME" "$USERHOME"

###############################################################################
# Install dependencies, build Python from source, and set up the venv
###############################################################################
RUN apk update --no-cache && apk upgrade --no-cache && \
    apk add --no-cache \
    bash \
    build-base \
    bzip2-dev \
    ca-certificates \
    curl \
    gcc \
    git \
    jq \ 
    libffi-dev \
    make \
    neovim \
    nodejs \
    npm \
    openssl-dev \
    readline-dev \
    ripgrep \
    shadow \
    sqlite-dev \
    tree-sitter \
    wget \
    xz-dev \
    zlib-dev \
    libcap \
    libseccomp \
    linux-pam \
    # Configure basic PAM module (example)
    && echo "auth required pam_securetty.so" >> /etc/pam.d/login \
    \
    # Set timezone
    && ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone

###############################################################################
# Build Python from source
###############################################################################
RUN cd /tmp && \
    echo "Downloading Python ${PYTHON_VERSION}..." && \
    wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" && \
    echo "Extracting Python source..." && \
    tar xf "Python-${PYTHON_VERSION}.tgz" && \
    cd "Python-${PYTHON_VERSION}" && \
    echo "Configuring Python build..." && \
    ./configure --prefix=/opt/venv --enable-optimizations && \
    echo "Building Python..." && \
    make -j"$(nproc)" && \
    echo "Installing Python..." && \
    make install && \
    \
    # Clean up build artifacts
    cd / && \
    rm -rf /tmp/* && \
    \
    # Create a python-wrapper in /usr/local/bin
    echo '#!/bin/sh' > /usr/local/bin/python-wrapper && \
    echo 'exec /opt/venv/bin/python3.12 "$@"' >> /usr/local/bin/python-wrapper && \
    chmod 755 /usr/local/bin/python-wrapper && \
    \
    # Verify installation
    echo "Verifying Python installation..." && \
    ls -la /opt/venv/bin/ && \
    /opt/venv/bin/python3.12 --version

###############################################################################
# Create & configure virtual environment
###############################################################################
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/python -m ensurepip && \
    /opt/venv/bin/python -m pip install --upgrade pip setuptools wheel

###############################################################################
# Verify virtual environment setup
###############################################################################
RUN ls -la /opt/venv/lib/python3.12/ && \
    /opt/venv/bin/python -c "import encodings; print('✅ Python stdlib is intact in venv')" && \
    \
    # Install 'uv' CLI for pip environment management
    curl -fsSL https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv /usr/local/bin/uv && \
    chmod +x /usr/local/bin/uv && \
    chown pythondev:pythondev /usr/local/bin/uv && \
    \
    # Verify uv + Python compatibility
    /opt/venv/bin/python -c "import encodings; print('✅ Python stdlib is intact in uv venv')"

###############################################################################
# Install Python dependencies from requirements.txt (if any)
###############################################################################
COPY --chown=$USERNAME:$USERNAME requirements.txt /tmp/requirements.txt
RUN uv pip install --system --no-cache -r /tmp/requirements.txt

###############################################################################
# Additional hardening: audit, remove SUID/SGID, disable core dumps, etc.
###############################################################################
RUN apk add --no-cache audit && \
    # Enable process auditing (may not work fully on Alpine)
    auditctl -e 1 || true && \
    \
    # Disable core dumps
    echo "* hard core 0" >> /etc/security/limits.conf && \
    \
    # Set recursive immutable bit on system files (may fail in containers)
    chattr -R +i /etc/passwd /etc/group /etc/shadow || true && \
    \
    # Remove setuid/setgid binaries
    find / -type f -perm /6000 -exec chmod a-s {} \; || true

###############################################################################
# Configure Neovim (LazyVim) and user .config
###############################################################################
RUN git clone --depth 1 https://github.com/LazyVim/starter "$USERHOME/.config/nvim" && \
    rm -rf "$USERHOME/.config/nvim/.git" && \
    rm -f "$USERHOME/.config/nvim/lua/plugins/example.lua" && \
    touch "$USERHOME/.config/nvim/lazy-lock.json" && \
    chown -R "$USERNAME":"$USERNAME" "$USERHOME/.config"

###############################################################################
# Harden the Alpine distribution for security (dev environment)
###############################################################################
RUN rm -rf /opt/venv/lib/python3.12/test/ \
    && rm -rf /opt/venv/lib/python3.12/tests/ \
    && rm -rf /opt/venv/lib/python3.12/__pycache__/ \
    && find /opt/venv -type d -name "__pycache__" -exec rm -r {} + \
    && find /opt/venv -type f -name "*.py[co]" -delete \
    && find /opt/venv -type f -name "*.a" -delete \
    && find /opt/venv -type f -name "*.la" -delete \
    \
    # Remove cron
    && rm -rf /var/spool/cron /etc/crontabs /etc/periodic \
    \
    # Remove unneeded binaries from /sbin /usr/sbin (except apk, ln)
    && find /sbin /usr/sbin ! -type d -a ! -name apk -a ! -name ln -delete || true \
    \
    # Remove world-writable bits
    && find / -xdev -type d -perm /0002 -exec chmod o-w {} + \
    && find / -xdev -type f -perm /0002 -exec chmod o-w {} + \
    && chmod 777 /tmp/ \
    \
    # Lock down user/group entries
    && sed -i -r '/^(root|nobody|'"$USERNAME"')/!d' /etc/group \
    && sed -i -r '/^(root|nobody|'"$USERNAME"')/!d' /etc/passwd \
    && sed -i -r '/^(root|nobody):/ s#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd \
    && while IFS=: read -r user _; do \
    if [ "$user" != "$USERNAME" ]; then \
    passwd -l "$user" || true; \
    fi; \
    done < /etc/passwd \
    \
    # Remove trailing dash-named binaries
    && find /bin /etc /lib /sbin /usr -xdev -type f -regex '.*-$' -exec rm -f {} \; \
    \
    # Ensure everything is owned by root:root and locked down
    && find /bin /etc /lib /sbin /usr -xdev -type d -exec chown root:root {} \; -exec chmod 0755 {} \; \
    \
    # Ensure /usr/local/bin exists
    && mkdir -p /usr/local/bin \
    && chmod 755 /usr/local/bin \
    \
    # Symlinks for python, python3
    && ln -sf /opt/venv/bin/python3.12 /usr/local/bin/python \
    && ln -sf /opt/venv/bin/python3.12 /usr/local/bin/python3 \
    \
    # Create a final python-wrapper
    && echo '#!/bin/sh' > /usr/local/bin/python-wrapper \
    && echo 'exec /opt/venv/bin/python3.12 "$@"' >> /usr/local/bin/python-wrapper \
    && chmod 755 /usr/local/bin/python-wrapper \
    \
    # Final cleanup of caches
    && rm -rf /var/cache/apk/* /tmp/* /root/.ash_history

###############################################################################
# Copy top-level shell configs and Neovim configuration
###############################################################################
COPY --chown=$USERNAME:$USERNAME \
    .bash_aliases \
    .bash_profile \
    .bashrc \
    .env \
    .gitignore \
    $USERHOME/

COPY --chown=$USERNAME:$USERNAME plugins/disabled.lua    $USERHOME/.config/nvim/lua/plugins/disabled.lua
COPY --chown=$USERNAME:$USERNAME plugins/ui.lua          $USERHOME/.config/nvim/lua/plugins/ui.lua
COPY --chown=$USERNAME:$USERNAME plugins/coding.lua      $USERHOME/.config/nvim/lua/plugins/coding.lua
COPY --chown=$USERNAME:$USERNAME plugins/toggleterm.lua  $USERHOME/.config/nvim/lua/plugins/toggleterm.lua
COPY --chown=$USERNAME:$USERNAME plugins/telescope.lua   $USERHOME/.config/nvim/lua/plugins/telescope.lua

###############################################################################
# Permanently set up the Python environment & PATH
###############################################################################
RUN set -eux; \
    echo 'export PYTHONHOME="/opt/venv"' > /etc/profile.d/python.sh && \
    echo 'export PYTHONPATH="/opt/venv/lib/python3.12/site-packages"' >> /etc/profile.d/python.sh && \
    echo 'export PATH="/opt/venv/bin:$PATH"' >> /etc/profile.d/python.sh && \
    chmod +x /etc/profile.d/python.sh && \
    \
    # Add source commands to relevant profiles
    echo 'source /etc/profile.d/python.sh' >> /etc/profile && \
    echo 'source /etc/profile.d/python.sh' >> "$USERHOME/.profile" && \
    echo 'source /etc/profile.d/python.sh' >> "$USERHOME/.bash_profile" && \
    echo 'source /etc/profile.d/python.sh' >> "$USERHOME/.bashrc" && \
    echo '[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"' >> "$USERHOME/.bash_profile" && \
    \
    # Ensure correct ownership of user files
    chown "$USERNAME":"$USERNAME" \
    "$USERHOME/.profile" \
    "$USERHOME/.bash_profile" \
    "$USERHOME/.bashrc"

###############################################################################
# Change 'pythondev' user's default shell to Bash and create code directory
###############################################################################
RUN chsh -s /bin/bash "$USERNAME" && \
    mkdir -p "$USERHOME/code" && \
    chown -R "$USERNAME:$USERNAME" "$USERHOME/code"

###############################################################################
# Implement resource limits (may not fully apply in containers)
###############################################################################
RUN ulimit -n 1024 && ulimit -u 100 || true

###############################################################################
# Switch to 'pythondev' (UID 1000) to avoid running as root
###############################################################################
USER 1000

###############################################################################
# Default working directory
###############################################################################
WORKDIR /home/pythondev/code

###############################################################################
# Updated Healthcheck (interval=300s)
###############################################################################
HEALTHCHECK --interval=300s --timeout=10s --start-period=5s --retries=3 \
    CMD python --version && \
    test "$(find / -type f -perm /2000 -o -perm /4000 | wc -l)" -eq 0 && \
    ps aux | grep -v pythondev | grep -v root | wc -l | grep -q '^0$' || exit 1

###############################################################################
# Default Command
###############################################################################
CMD ["/bin/bash"]
