---
layout: index
title: "pythondev — Portable, Hardened Python 3.12+ AI Developer Container"
name: "pythondev"
headline: "Hardened Python 3.12+ Development Container for AI Agents"
lead: "High-performance Python container preloaded with uv, ruff, mypy, pytest, debugpy, Pyright LSP, 4-pane TMUX IDE, and stdio Model Context Protocol (MCP) server."
permalink: "/"
language: "en-GB"
date: "2026-08-29"
---

<section id="overview" class="section">
  <div class="container text-center">
    <h2 class="section-title">Engineered for Python Developers & Terminal AI Agents</h2>
    <p class="section-desc">Ultra-fast Python workflows powered by uv package manager, Pyright LSP, and native MCP container tooling.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Python 3.12+ Toolchain</h3>
        <p>Pre-installed with <code>uv</code> for instant virtualenvs and package resolution, <code>ruff</code> linter/formatter, <code>mypy</code>, and <code>pytest</code>.</p>
      </div>
      <div class="card">
        <h3>4-Pane TMUX IDE (Prefix + i)</h3>
        <p>Dedicated split layout with File Tree Explorer, Neovim (Pyright LSP + Ruff), terminal shell, and AI Agent pane.</p>
      </div>
      <div class="card">
        <h3>Parallel AI Task Worktrees (muxtree)</h3>
        <p>Automate Git worktrees paired with separate TMUX sessions for concurrent multi-agent and human feature branches.</p>
      </div>
      <div class="card">
        <h3>Model Context Protocol (MCP)</h3>
        <p>Stdio JSON-RPC 2.0 interface exposing pytest execution, python file discovery, and repository diagnostics to Claude Code and Cursor.</p>
      </div>
    </div>
  </div>
</section>

<section id="quickstart" class="section">
  <div class="container narrow">
    <h2 class="section-title text-center">Quick Start in 30 Seconds</h2>
    <p class="section-desc text-center">Disposable Python development environment running on Docker or Podman.</p>
    <pre><code># 1. Clone the repository
git clone https://github.com/sebastienrousseau/pythondev.git
cd pythondev

# 2. Build and launch 4-pane TMUX IDE
make up

# 3. Mobile WebTTY (port 7681) & Mosh roaming
make web
make mosh</code></pre>
  </div>
</section>

<section id="suite" class="section">
  <div class="container">
    <h2 class="section-title text-center">Unified Multi-Language Suite</h2>
    <p class="section-desc text-center">Every container shares an identical security baseline, TMUX shortcuts, and MCP interfaces.</p>
    <div class="table-responsive">
      <table>
        <thead>
          <tr>
            <th>Container</th>
            <th>Language Stack</th>
            <th>Built-in Tooling</th>
            <th>Version</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>langdev</strong></td>
            <td>Core Foundation</td>
            <td>TMUX IDE, MCP server, ai-pack, WebTTY, OSC 52</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><strong>pythondev</strong></td>
            <td>Python 3.12+</td>
            <td>uv, ruff, mypy, pytest, debugpy, Pyright</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><strong>rustdev</strong></td>
            <td>Rust 1.85+</td>
            <td>rustup, rust-analyzer, clippy, cargo-audit, sccache</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><strong>godev</strong></td>
            <td>Go 1.24+</td>
            <td>gopls, golangci-lint, delve, Go toolchain</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><strong>javadev</strong></td>
            <td>Java 21+</td>
            <td>OpenJDK 21, Maven, Gradle, JDTLS</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><strong>kotlindev</strong></td>
            <td>Kotlin 2.1+</td>
            <td>kotlinc, OpenJDK 21, Gradle, Maven, KLS</td>
            <td>v0.0.4</td>
          </tr>
          <tr>
            <td><strong>swiftdev</strong></td>
            <td>Swift 6.0+</td>
            <td>Swift toolchain, SourceKit-LSP, swift-format</td>
            <td>v0.0.4</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</section>

<section id="security" class="section">
  <div class="container text-center">
    <h2 class="section-title">Zero-Trust Hardened Security</h2>
    <p class="section-desc">Strict security guarantees verified in CI and container runtime.</p>
    <div class="grid-2x2">
      <div class="card">
        <h3>Unprivileged Non-Root</h3>
        <p>Runs as unprivileged dev user (UID/GID 1000). Drops all Linux capabilities (<code>cap_drop: [ALL]</code>) with <code>no-new-privileges:true</code>.</p>
      </div>
      <div class="card">
        <h3>Read-Only Root Filesystem</h3>
        <p>Immutable rootfs prevents container modification or persistent malware. Writable state is restricted to explicit tmpfs mounts.</p>
      </div>
      <div class="card">
        <h3>Supply Chain Integrity</h3>
        <p>Base images pinned to cryptographic SHA256 digests. Zero unpinned curl-to-sh scripts. Automated CycloneDX SBOM generation.</p>
      </div>
      <div class="card">
        <h3>Hermetic CI & SAST</h3>
        <p>100% unit tested with Bats, ShellCheck linting, Hadolint OCI auditing, and Trivy CVE vulnerability scans.</p>
      </div>
    </div>
  </div>
</section>

<section id="faq" class="section">
  <div class="container narrow">
    <h2 class="section-title text-center">Frequently Asked Questions</h2>
    <div class="stack" style="display:flex; flex-direction:column; gap:1.5rem; margin-top:2rem;">
      <div class="card">
        <h3>What package manager is used?</h3>
        <p><code>uv</code> is pre-installed for ultra-fast package resolution and pip replacement.</p>
      </div>
      <div class="card">
        <h3>How fast is the container cold start?</h3>
        <p>Under 500 milliseconds. All dotfiles, Python runtimes, and linters are baked at build time.</p>
      </div>
    </div>
  </div>
</section>
