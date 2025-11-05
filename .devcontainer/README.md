# DevContainer Setup for GitHub Migrator

This directory contains the configuration for running the GitHub Migrator project in a VS Code DevContainer or GitHub Codespaces.

## 🚀 Quick Start

### Prerequisites

- **Docker Desktop** (for local development)
  - macOS: [Download Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
  - Windows: [Download Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
  - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/)
- **VS Code** with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- **Corporate SSL Certificates** (if behind a proxy with SSL inspection) - see [Certificate Setup](#-ssl-certificate-setup)

### Opening the DevContainer

1. **Clone the repository:**
   ```bash
   git clone https://github.com/harris-boyce/GitHub-migrator.git
   cd GitHub-migrator
   ```

2. **Open in VS Code:**
   ```bash
   code .
   ```

3. **Reopen in Container:**
   - Press `F1` or `Cmd+Shift+P` (macOS) / `Ctrl+Shift+P` (Windows/Linux)
   - Type: `Dev Containers: Reopen in Container`
   - Wait for the container to build (first time takes 3-5 minutes)

4. **Verify Setup:**
   - Terminal should open automatically
   - Check Go version: `go version`
   - Check Node version: `node --version`

## 📦 What's Included

### Base Image
- **Go 1.23** (Debian Bookworm-based)
- **Node.js 20** (via devcontainer feature)
- **GitHub CLI** (via devcontainer feature)

### Development Tools
- **Go Tools:**
  - `air` - Live reload for Go applications
  - `gopls` - Go language server
  - `dlv` - Delve debugger
- **Git Tools:**
  - `git-lfs` - Large File Storage
  - `git-sizer` - Repository size analysis
- **VS Code Extensions:**
  - Go extension
  - ESLint
  - Prettier
  - Docker
  - GitLens
  - Tailwind CSS IntelliSense
  - And more (see `devcontainer.json`)

### Port Forwarding
- **8080** - Backend API server
- **5173** - Frontend Vite dev server

## 🔐 SSL Certificate Setup

If you're behind a corporate proxy with SSL inspection (Netskope, Zscaler, Cisco, etc.), you'll need to add your corporate certificates before building the container.

### Quick Setup

1. **Export your certificates** to `.devcontainer/corporate-certs/`:

   **macOS:**
   ```bash
   # Create the directory
   mkdir -p .devcontainer/corporate-certs

   # Export corporate root CA (replace with your cert name)
   security find-certificate -c "Netskope" -a -p > .devcontainer/corporate-certs/netskope-ca.crt
   ```

   **Windows (PowerShell):**
   ```powershell
   # Create the directory
   New-Item -Path ".devcontainer\corporate-certs" -ItemType Directory -Force

   # Export certificate (replace with your cert name)
   $cert = Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object {$_.Subject -like "*Netskope*"}
   $cert | Export-Certificate -FilePath ".devcontainer\corporate-certs\netskope-ca.crt" -Type CERT
   ```

2. **Build the container** - certificates will be automatically installed during the Docker build

For detailed certificate setup instructions, see [CERTIFICATE_SETUP.md](./CERTIFICATE_SETUP.md).

## 🏗️ Architecture

### Container Build Process

1. **Dockerfile** - Builds custom image with corporate certificates
   - Copies certificates from `.devcontainer/corporate-certs/`
   - Installs certificates at `/usr/local/share/ca-certificates/corporate/`
   - Runs `update-ca-certificates`
   - Sets SSL environment variables

2. **DevContainer Features** - Adds Node.js and GitHub CLI
   - Features have access to installed certificates

3. **Post-Create Script** - Runs after container is created
   - Configures git SSL settings
   - Installs git-lfs
   - Downloads Go dependencies
   - Installs Go development tools
   - Downloads git-sizer
   - Installs npm packages

### File Structure

```
.devcontainer/
├── devcontainer.json          # Main configuration
├── Dockerfile                 # Custom image with certificates
├── post-create.sh            # Post-creation setup script
├── CERTIFICATE_SETUP.md      # Detailed certificate documentation
├── README.md                 # This file
└── corporate-certs/          # Your corporate certificates (git-ignored)
    ├── netskope-ca.crt       # Example: Netskope root CA
    └── company-root-ca.crt   # Example: Company root CA
```

## 🛠️ Development Workflow

### Running the Backend

```bash
# Using Air for live reload (recommended)
air

# Or run directly
go run cmd/server/main.go
```

### Running the Frontend

```bash
cd web
npm run dev
```

### Running Tests

```bash
# Go tests
go test ./...

# Go tests with coverage
go test -cover ./...

# Frontend tests
cd web
npm test
```

### Database Setup

The PostgreSQL database runs in a separate container via `docker-compose.yml`:

```bash
# Start the database
docker-compose up -d

# Check database logs
docker-compose logs -f postgres

# Stop the database
docker-compose down
```

## 🐛 Troubleshooting

### Container Build Fails with SSL Errors

**Problem:** Git, npm, or Go fails with SSL certificate errors during build.

**Solution:**
1. Verify you've added corporate certificates to `.devcontainer/corporate-certs/`
2. Check certificates are in PEM format with `.crt` extension
3. Rebuild container: `Dev Containers: Rebuild Container`

See [CERTIFICATE_SETUP.md](./CERTIFICATE_SETUP.md) for detailed troubleshooting.

### Port Already in Use

**Problem:** Port 8080 or 5173 is already in use.

**Solution:**
1. Stop the conflicting process:
   ```bash
   # macOS/Linux
   lsof -ti:8080 | xargs kill -9
   ```
2. Or change the port in `devcontainer.json`:
   ```json
   "forwardPorts": [8081, 5174]
   ```

### Go Tools Not Working

**Problem:** `gopls` or other Go tools aren't working.

**Solution:**
1. Reinstall Go tools:
   ```bash
   go install golang.org/x/tools/gopls@latest
   ```
2. Reload VS Code window: `Developer: Reload Window`

### Git-LFS Not Working

**Problem:** Git LFS objects aren't downloading.

**Solution:**
1. Reinstall git-lfs:
   ```bash
   sudo apt-get update && sudo apt-get install --reinstall git-lfs
   git lfs install
   ```
2. Pull LFS objects:
   ```bash
   git lfs pull
   ```

### Frontend Dependencies Fail to Install

**Problem:** `npm ci` fails during post-create.

**Solution:**
1. Check if certificates are installed (for SSL errors)
2. Clear npm cache and retry:
   ```bash
   cd web
   npm cache clean --force
   npm ci
   ```

## 🌐 GitHub Codespaces

This devcontainer is fully compatible with GitHub Codespaces.

### Opening in Codespaces

1. Go to the repository on GitHub
2. Click the green **Code** button
3. Select the **Codespaces** tab
4. Click **Create codespace on main**

### Certificate Handling in Codespaces

Codespaces runs in the cloud and doesn't need corporate certificates. The Dockerfile gracefully handles missing certificates, so it works in both scenarios:
- **Local with corporate proxy:** Uses certificates from `.devcontainer/corporate-certs/`
- **Codespaces:** Skips certificates (none needed in cloud)

## 📚 Additional Resources

- [CERTIFICATE_SETUP.md](./CERTIFICATE_SETUP.md) - Detailed SSL certificate setup guide
- [VS Code DevContainers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Project Documentation](../docs/) - Main project docs

## 🤝 Contributing

When contributing to the devcontainer configuration:

1. Test changes locally before committing
2. Ensure the container builds without certificates (for Codespaces compatibility)
3. Update this README if adding new features or tools
4. Never commit certificates (they're git-ignored)

## 📝 Notes

- **Data Persistence:** The `data/` and `logs/` directories are mounted from the host, so they persist between container rebuilds
- **Git Ignored:** Corporate certificates in `.devcontainer/corporate-certs/` are automatically git-ignored for security
- **Offline Mode:** Once built, the container works offline (all dependencies are cached)
- **Performance:** First build takes 3-5 minutes; subsequent rebuilds are faster (~1-2 minutes)
