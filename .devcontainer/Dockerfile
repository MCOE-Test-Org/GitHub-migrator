FROM mcr.microsoft.com/devcontainers/go:1.25-bookworm

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

# Install tflint (after certificates are set up)
RUN TFLINT_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//') && \
    wget -q "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" && \
    unzip tflint_linux_amd64.zip -d /usr/local/bin && \
    rm tflint_linux_amd64.zip && \
    chmod +x /usr/local/bin/tflint && \
    echo "tflint ${TFLINT_VERSION} installed"

# Install terragrunt (after certificates are set up)
RUN TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//') && \
    wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" -O /usr/local/bin/terragrunt && \
    chmod +x /usr/local/bin/terragrunt && \
    echo "terragrunt ${TERRAGRUNT_VERSION} installed"

# Verify installations
RUN tflint --version && terragrunt --version
