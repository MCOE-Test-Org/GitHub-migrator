FROM mcr.microsoft.com/devcontainers/go:1.25-bookworm

# Build arguments for tool versions
ARG TERRAFORM_VERSION=latest
ARG TFLINT_VERSION=latest
ARG TERRAGRUNT_VERSION=latest

# Install ca-certificates package
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Create directory for corporate certificates
RUN mkdir -p /usr/local/share/ca-certificates/corporate

# Copy corporate certificates directory (will contain certs or be empty)
COPY .devcontainer/corporate-certs /tmp/corporate-certs-temp

# Move certificates if any exist
RUN if [ -n "$(ls -A /tmp/corporate-certs-temp/*.crt 2>/dev/null)" ]; then \
        cp /tmp/corporate-certs-temp/*.crt /usr/local/share/ca-certificates/corporate/ && \
        echo "Corporate certificates copied"; \
    else \
        echo "No corporate certificates found"; \
    fi && \
    rm -rf /tmp/corporate-certs-temp

# Update CA certificates if any were copied
RUN if [ -n "$(ls -A /usr/local/share/ca-certificates/corporate/ 2>/dev/null)" ]; then \
        echo "Installing corporate certificates..." && \
        update-ca-certificates && \
        echo "Corporate certificates installed successfully"; \
    else \
        echo "No corporate certificates found - continuing without them"; \
    fi

# Set environment variables for SSL certificate locations
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

# Install additional tools after certificates are configured
# Install unzip and wget for downloading tools
RUN apt-get update && apt-get install -y unzip wget && rm -rf /var/lib/apt/lists/*

# Install Terraform (after certificates are set up)
RUN if [ "$TERRAFORM_VERSION" = "latest" ]; then \
        TF_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//'); \
    else \
        TF_VERSION=$TERRAFORM_VERSION; \
    fi && \
    if [ -z "$TF_VERSION" ]; then \
        echo "ERROR: Failed to fetch Terraform version from GitHub API. You may have hit a rate limit or the API response format has changed." >&2; \
        exit 1; \
    fi && \
    wget -q "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" && \
    unzip terraform_${TF_VERSION}_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_${TF_VERSION}_linux_amd64.zip && \
    chmod +x /usr/local/bin/terraform
# Install tflint (after certificates are set up)
RUN if [ "$TFLINT_VERSION" = "latest" ]; then \
        TFL_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//'); \
    else \
        TFL_VERSION=$TFLINT_VERSION; \
    fi && \
    if [ -z "$TFL_VERSION" ]; then \
        echo "ERROR: Failed to fetch TFLint version from GitHub API. You may have hit a rate limit or the API response format has changed." >&2; \
        exit 1; \
    fi && \
    wget -q "https://github.com/terraform-linters/tflint/releases/download/v${TFL_VERSION}/tflint_linux_amd64.zip" && \
    unzip tflint_linux_amd64.zip -d /usr/local/bin && \
    rm tflint_linux_amd64.zip && \
    chmod +x /usr/local/bin/tflint && \
    echo "tflint ${TFL_VERSION} installed"
    chmod +x /usr/local/bin/tflint && \
    echo "tflint ${TFL_VERSION} installed"

# Install terragrunt (after certificates are set up)
RUN if [ "$TERRAGRUNT_VERSION" = "latest" ]; then \
        TG_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//'); \
    else \
        TG_VERSION=$TERRAGRUNT_VERSION; \
    fi && \
    if [ -z "$TG_VERSION" ]; then \
        echo "ERROR: Failed to fetch Terragrunt version from GitHub API. You may have hit a rate limit or the API response format has changed." >&2; \
        exit 1; \
    fi && \
    wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/v${TG_VERSION}/terragrunt_linux_amd64" -O /usr/local/bin/terragrunt && \
    chmod +x /usr/local/bin/terragrunt && \
    echo "terragrunt ${TG_VERSION} installed"

# Verify installations
RUN terraform --version && tflint --version && terragrunt --version
