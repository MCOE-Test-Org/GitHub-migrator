#!/bin/bash
set -e

echo "🚀 Starting devcontainer post-create setup..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configure git to use system certificates
echo -e "${BLUE}🔐 Configuring Git SSL settings...${NC}"
git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt
echo -e "${GREEN}✓ Git SSL configuration set${NC}"

# Create necessary directories
echo -e "${BLUE}📁 Creating data and logs directories...${NC}"
mkdir -p data logs
echo -e "${GREEN}✓ Directories created${NC}"

# Install git-lfs via apt (avoiding SSL certificate issues)
echo -e "${BLUE}📦 Installing git-lfs...${NC}"
sudo apt-get update -qq && sudo apt-get install -y git-lfs
git lfs install
echo -e "${GREEN}✓ git-lfs installed${NC}"

# Download Go dependencies
echo -e "${BLUE}📦 Downloading Go dependencies...${NC}"
go mod download
echo -e "${GREEN}✓ Go dependencies downloaded${NC}"

# Install Go development tools
echo -e "${BLUE}🔧 Installing Go development tools...${NC}"
go install github.com/air-verse/air@latest
go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
echo -e "${GREEN}✓ Go tools installed${NC}"

# Download git-sizer binaries
echo -e "${BLUE}📥 Downloading git-sizer binaries...${NC}"
if [ -f "scripts/download-git-sizer.sh" ]; then
    chmod +x scripts/download-git-sizer.sh
    ./scripts/download-git-sizer.sh
    echo -e "${GREEN}✓ git-sizer downloaded${NC}"
else
    echo "⚠️  git-sizer download script not found, skipping..."
fi

# Install frontend dependencies
echo -e "${BLUE}📦 Installing frontend dependencies...${NC}"
cd web
npm ci
echo -e "${GREEN}✓ Frontend dependencies installed${NC}"
cd ..

# Copy config template if config doesn't exist
echo -e "${BLUE}⚙️  Setting up configuration...${NC}"
if [ ! -f "configs/config.yaml" ] && [ -f "configs/config_template.yml" ]; then
    cp configs/config_template.yml configs/config.yaml
    echo -e "${GREEN}✓ Config file created from template${NC}"
else
    echo "ℹ️  Config file already exists or template not found"
fi

# Initialize SQLite database directory
echo -e "${BLUE}🗄️  Initializing database...${NC}"
touch data/.gitkeep
echo -e "${GREEN}✓ Database directory initialized${NC}"

echo -e "${GREEN}🎉 Devcontainer setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Start the backend: make run (or 'air' for hot reload)"
echo "  2. Start the frontend: cd web && npm run dev"
echo "  3. Access the app at http://localhost:5173"
echo ""
