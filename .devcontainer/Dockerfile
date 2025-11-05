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
