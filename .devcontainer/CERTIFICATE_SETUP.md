# Certificate and Proxy Configuration for DevContainers

This guide helps you configure the devcontainer to work with corporate proxies and self-signed SSL certificates.

## Overview

This devcontainer uses a **custom Dockerfile** that installs corporate certificates during the image build process. This ensures that all devcontainer features (Node.js, GitHub CLI) and tools trust your corporate certificates from the start.

**Important**: Certificates are stored in `.devcontainer/corporate-certs/` which is **git-ignored** and must be set up locally by each developer.

---

## Quick Start Guide

### For macOS Users

```bash
# 1. Create the corporate-certs directory
mkdir -p .devcontainer/corporate-certs

# 2. Export your corporate certificates from Keychain
# Replace "YourCompanyName" with your actual company name or certificate name

# Export root CA
security find-certificate -c "Root CA" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/root-ca.crt

# Export SSL inspection proxy (Netskope, Zscaler, etc.)
security find-certificate -c "netskope" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/proxy-ca.crt

# Export any intermediate CAs
security find-certificate -c "Internal Certificate Authority" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/internal-ca.crt

# 3. Verify certificates are in PEM format
openssl x509 -in .devcontainer/corporate-certs/root-ca.crt -text -noout

# 4. Rebuild devcontainer
# In VS Code: Cmd+Shift+P → "Dev Containers: Rebuild Container"
```

### For Windows Users

```powershell
# 1. Create the corporate-certs directory
New-Item -ItemType Directory -Force -Path .devcontainer\corporate-certs

# 2. Export certificates from Windows Certificate Store
# Open Certificate Manager (certmgr.msc)
# Navigate to: Trusted Root Certification Authorities → Certificates
# Find your corporate certificates, right-click → All Tasks → Export
# Choose "Base-64 encoded X.509 (.CER)" format
# Save to: .devcontainer\corporate-certs\

# 3. Rename files to .crt extension
Rename-Item .devcontainer\corporate-certs\*.cer -NewName {$_.name -replace '\.cer$','.crt'}

# 4. Verify certificate format
# In PowerShell or Git Bash:
openssl x509 -in .devcontainer/corporate-certs/root-ca.crt -text -noout

# 5. Rebuild devcontainer
# In VS Code: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

---

**Accepted Formats:**
- **PEM** (Privacy Enhanced Mail) - Text format, Base64 encoded
  - Extensions: `.crt`, `.pem`, `.cer`
  - Starts with: `-----BEGIN CERTIFICATE-----`
  - Ends with: `-----END CERTIFICATE-----`
  - ✅ This is the REQUIRED format for Linux containers

- **DER** (Distinguished Encoding Rules) - Binary format
  - Extensions: `.cer`, `.der`
  - Binary file (not human-readable)
  - ❌ Must be converted to PEM for container use

**How to Identify Your Certificate Format:**

```bash
# View the file - if you see "BEGIN CERTIFICATE", it's PEM
cat certificate.crt

# If binary data appears, it's DER - convert it:
openssl x509 -inform der -in certificate.cer -out certificate.crt

# Verify the conversion worked:
openssl x509 -in certificate.crt -text -noout
```

---

## Certificate Format Requirements

**Accepted Formats:**
- **PEM** (Privacy Enhanced Mail) - Text format, Base64 encoded
  - Extensions: `.crt`, `.pem`, `.cer`
  - Starts with: `-----BEGIN CERTIFICATE-----`
  - Ends with: `-----END CERTIFICATE-----`
  - ✅ This is the REQUIRED format for the devcontainer

- **DER** (Distinguished Encoding Rules) - Binary format
  - Extensions: `.cer`, `.der`
  - Binary file (not human-readable)
  - ❌ Must be converted to PEM for container use

**Certificate File Naming:**
- Files MUST have `.crt` extension (e.g., `corporate-ca.crt`)
- Multiple certificates can be stored as separate files
- All `.crt` files in `.devcontainer/corporate-certs/` will be installed

**How to Identify Your Certificate Format:**

```bash
# View the file - if you see "BEGIN CERTIFICATE", it's PEM
cat .devcontainer/corporate-certs/certificate.crt

# If binary data appears, it's DER - convert it:
openssl x509 -inform der -in certificate.cer -out certificate.crt

# Verify the conversion worked:
openssl x509 -in certificate.crt -text -noout
```

---

## Detailed Setup Instructions

### Step 1: Identify Required Certificates

You typically need these certificates from your organization:

1. **Root CA Certificate** - The top-level certificate authority
2. **Intermediate CA Certificate(s)** - Middle certificates in the chain  
3. **SSL Inspection Proxy Certificate** - If using Netskope, Zscaler, etc.

**How to find them:**
- **macOS**: Open Keychain Access → System → Certificates
- **Windows**: Run `certmgr.msc` → Trusted Root Certification Authorities
- Look for certificates issued by your company name

### Step 2: Export Certificates

#### macOS - Export from Keychain

```bash
# List all certificates to find the right names
security find-certificate -a /Library/Keychains/System.keychain | grep "labl"

# Export specific certificate by name
security find-certificate -c "Certificate Name" -p \
  /Library/Keychains/System.keychain > .devcontainer/corporate-certs/cert-name.crt

# Common examples:
security find-certificate -c "Slalom" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/slalom-root-ca.crt

security find-certificate -c "netskope" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/netskope-ca.crt
```

#### Windows - Export from Certificate Manager

1. Press `Win+R`, type `certmgr.msc`, press Enter
2. Navigate to **Trusted Root Certification Authorities** → **Certificates**
3. Find your corporate certificate(s)
4. Right-click → **All Tasks** → **Export**
5. Click **Next**, select **Base-64 encoded X.509 (.CER)**
6. Save to `.devcontainer\corporate-certs\`
7. Rename from `.cer` to `.crt`:
   ```powershell
   Rename-Item .devcontainer\corporate-certs\*.cer -NewName {$_.name -replace '\.cer$','.crt'}
   ```

#### Linux - Export from System Store

```bash
# Copy from system certificate directory
sudo cp /etc/ssl/certs/your-company-ca.pem \
  .devcontainer/corporate-certs/company-ca.crt

# Or export from Firefox/Chrome certificates
# Firefox: Settings → Privacy & Security → Certificates → View Certificates
# Export as PEM format
```

### Step 3: Verify Certificate Format

```bash
# Should display certificate details (not binary data)
openssl x509 -in .devcontainer/corporate-certs/your-cert.crt -text -noout

# Check all certificates at once
for cert in .devcontainer/corporate-certs/*.crt; do
  echo "Checking $cert"
  openssl x509 -in "$cert" -noout -subject -issuer
done
```

### Step 4: Rebuild Devcontainer

The Dockerfile will automatically:
1. Copy all `.crt` files from `.devcontainer/corporate-certs/`
2. Install them into the system trust store
3. Configure environment variables for all tools

**Rebuild the container:**
- VS Code: `Cmd/Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
- Or: Delete container and reopen in container

---

## How the Certificate Installation Works

### Architecture

The devcontainer uses a **multi-stage approach**:

1. **Dockerfile Build Phase**:
   ```dockerfile
   # Copies certificates during image build
   COPY .devcontainer/corporate-certs /tmp/corporate-certs-temp
   RUN cp /tmp/corporate-certs-temp/*.crt /usr/local/share/ca-certificates/corporate/
   RUN update-ca-certificates
   ```

2. **Environment Configuration**:
   ```dockerfile
   ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
   ENV CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
   ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
   ```

3. **Post-Create Script**:
   - Installs git-lfs via apt (avoids SSL issues during build)
   - Configures git to use system certificates
   - Installs Go dependencies, npm packages, etc.

### File Locations

```
GitHub-migrator/
├── .devcontainer/
│   ├── Dockerfile                    # Builds custom image with certs
│   ├── devcontainer.json            # References Dockerfile
│   ├── corporate-certs/             # ⚠️ GIT-IGNORED - Your certs go here
│   │   ├── root-ca.crt
│   │   ├── intermediate-ca.crt
│   │   └── proxy-ca.crt
│   ├── post-create.sh               # Post-container setup
│   └── CERTIFICATE_SETUP.md         # This file
└── .gitignore                       # Excludes corporate-certs/
```

**Security Notes:**
- `.devcontainer/corporate-certs/` is in `.gitignore`
- Certificates are NEVER committed to git
- Each developer sets up their own certificates locally
- Safe to share the repo without exposing certificates

---

## Common Proxy/SSL Inspection Tools

### Netskope

```bash
# macOS
security find-certificate -c "netskope" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/netskope-ca.crt

# You may need multiple Netskope certificates:
security find-certificate -c "caadmin.netskope.com" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/netskope-admin-ca.crt
```

### Zscaler

```bash
# macOS  
security find-certificate -c "Zscaler" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/zscaler-root-ca.crt
```

### Cisco Umbrella

```bash
# macOS
security find-certificate -c "Cisco Umbrella" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/cisco-umbrella-ca.crt
```

---

## Proxy Configuration

### Docker Desktop Proxy Setup

If your organization uses an HTTP/HTTPS proxy:

1. **macOS**:
   - Docker Desktop → Settings → Resources → Proxies
   - Enable "Manual proxy configuration"
   - Set HTTP Proxy: `http://proxy.company.com:8080`
   - Set HTTPS Proxy: `http://proxy.company.com:8080`
   - Set No Proxy: `localhost,127.0.0.1,.local`

2. **Windows**:
   - Docker Desktop → Settings → Resources → Proxies
   - Same configuration as macOS

### Environment Variables

The devcontainer automatically forwards proxy settings from your host:

```json
// In devcontainer.json
"remoteEnv": {
  "HTTP_PROXY": "${localEnv:HTTP_PROXY}",
  "HTTPS_PROXY": "${localEnv:HTTPS_PROXY}",
  "NO_PROXY": "${localEnv:NO_PROXY}"
}
```

**Set on your host:**

```bash
# macOS/Linux (~/.zshrc or ~/.bashrc)
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1,.local,.company.com"
```

```powershell
# Windows (PowerShell Profile)
$env:HTTP_PROXY="http://proxy.company.com:8080"
$env:HTTPS_PROXY="http://proxy.company.com:8080"
$env:NO_PROXY="localhost,127.0.0.1,.local"
```

---

## Testing & Verification

### Before Building Container

```bash
# Verify certificates are in the correct location
ls -la .devcontainer/corporate-certs/

# Check certificate format (should show details, not binary)
for cert in .devcontainer/corporate-certs/*.crt; do
  echo "=== $cert ==="
  openssl x509 -in "$cert" -noout -subject -issuer
done

# Test if Docker can build with certificates
docker build -f .devcontainer/Dockerfile -t test-devcontainer .
```

### After Container Builds

Open a terminal inside the devcontainer and run:

```bash
# 1. Check installed certificates
ls -la /usr/local/share/ca-certificates/corporate/
cat /etc/ssl/certs/ca-certificates.crt | grep "BEGIN CERTIFICATE" | wc -l

# 2. Test HTTPS connections
curl -I https://github.com
curl -I https://registry.npmjs.org
curl -I https://proxy.golang.org

# 3. Test git
git ls-remote https://github.com/golang/go.git HEAD

# 4. Test npm
npm config get registry
npm ping

# 5. Test Go modules
go env GOPROXY
go list -m golang.org/x/tools@latest

# 6. Check environment variables
echo $SSL_CERT_FILE
echo $CURL_CA_BUNDLE
echo $NODE_EXTRA_CA_CERTS
```

### Troubleshooting Test

```bash
# Test with verbose SSL output
curl -v https://github.com 2>&1 | grep -i "SSL\|certificate"

# Check which certificates are being used
openssl s_client -connect github.com:443 -showcerts

# Verify certificate chain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \
  /usr/local/share/ca-certificates/corporate/your-cert.crt
```

---

## Troubleshooting

### Issue: "SSL certificate problem: self-signed certificate in certificate chain"

### Issue: "SSL certificate problem: self-signed certificate in certificate chain"

**Cause**: Missing corporate certificate or SSL inspection proxy certificate

**Solutions**:
1. Identify which certificate is missing:
   ```bash
   curl -v https://github.com 2>&1 | grep "issuer:"
   ```
2. Export that specific certificate to `.devcontainer/corporate-certs/`
3. **Important**: If using SSL inspection proxy (Netskope, Zscaler), you MUST export that certificate
4. Rebuild container: `Dev Containers: Rebuild Container`

### Issue: Container builds but features fail to install

**Cause**: Certificates not installed before features run

**Solution**: This should be automatic with the Dockerfile approach. Verify:
```bash
# Check Dockerfile copies certificates before feature installation
cat .devcontainer/Dockerfile | grep -A5 "COPY.*corporate-certs"
```

### Issue: Certificates not found in container

**Cause**: Certificates not in `.devcontainer/corporate-certs/` or wrong format

**Check**:
```bash
# Verify certificates exist locally
ls -la .devcontainer/corporate-certs/*.crt

# Verify they're PEM format
file .devcontainer/corporate-certs/*.crt
# Should show: "PEM certificate" not "data"

# Check inside container
docker run --rm -v $(pwd)/.devcontainer/corporate-certs:/certs alpine ls -la /certs
```

### Issue: "Permission denied" when copying certificates

**macOS Solution**:
```bash
# Export from Keychain doesn't require sudo
security find-certificate -c "CertName" -p /Library/Keychains/System.keychain \
  > .devcontainer/corporate-certs/cert.crt
```

**Windows Solution**:
- Use Certificate Manager (`certmgr.msc`) - no admin rights needed
- Export to user-writable location first, then copy

### Issue: npm/go/git still fail with SSL errors

**Check environment variables**:
```bash
# Inside container
env | grep -E "SSL|CERT|CA"

# Should see:
# SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
# NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
```

**Manually configure if needed**:
```bash
# Git
git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt

# npm
npm config set cafile /etc/ssl/certs/ca-certificates.crt

# Go (should work automatically with SSL_CERT_FILE)
go env -w GOINSECURE=none  # Ensure SSL verification is on
```

### Issue: Certificate file doesn't work

**Check format:**
```bash
# Should output certificate details in readable text
openssl x509 -in certificate.crt -text -noout

# If you get an error, try DER format:
openssl x509 -inform der -in certificate.cer -text -noout

# Convert DER to PEM if needed:
openssl x509 -inform der -in certificate.cer -outform pem -out certificate.crt
```

### Issue: Multiple certificates in one file (certificate bundle)

**Split them into separate files:**
```bash
# If you have a bundle file (ca-bundle.crt), split it:
csplit -f cert- ca-bundle.crt '/-----BEGIN CERTIFICATE-----/' '{*}'

# Rename and move to certs directory:
mkdir -p ~/.devcontainer/certs
mv cert-01 ~/.devcontainer/certs/root-ca.crt
mv cert-02 ~/.devcontainer/certs/intermediate-ca.crt
```

Or keep as a single file - both approaches work.

### Issue: Windows certificate export creates .cer file

**Solution**:
```powershell
# Rename .cer to .crt
Get-ChildItem .devcontainer\corporate-certs\*.cer | Rename-Item -NewName {$_.Name -replace '\.cer$','.crt'}

# Verify they're PEM format (Base64), not DER (binary)
Get-Content .devcontainer\corporate-certs\cert.crt -Head 1
# Should show: -----BEGIN CERTIFICATE-----

# If binary, convert DER to PEM:
openssl x509 -inform der -in cert.cer -outform pem -out cert.crt
```

### Issue: Multiple certificates in one file (bundle)

**Solution - Split into separate files**:
```bash
# Use csplit to split by certificate markers
csplit -f .devcontainer/corporate-certs/cert- \
  ca-bundle.crt '/-----BEGIN CERTIFICATE-----/' '{*}'

# Rename with meaningful names
mv .devcontainer/corporate-certs/cert-01 .devcontainer/corporate-certs/root-ca.crt
mv .devcontainer/corporate-certs/cert-02 .devcontainer/corporate-certs/intermediate-ca.crt
```

**Or keep as bundle** (also works):
```bash
# Just ensure it has .crt extension
cp ca-bundle.pem .devcontainer/corporate-certs/ca-bundle.crt
```

### Issue: Devcontainer works but Codespaces fails

**Cause**: Codespaces doesn't have access to your local `.devcontainer/corporate-certs/`

**Solution**: This is expected behavior. The Dockerfile handles missing certificates gracefully:
```dockerfile
# Builds successfully even without certificates
RUN if [ -n "$(ls -A /tmp/corporate-certs-temp/*.crt 2>/dev/null)" ]; then
    cp /tmp/corporate-certs-temp/*.crt /usr/local/share/ca-certificates/corporate/
fi
```

**For Codespaces**:
- Use without corporate certificates if possible
- Or use GitHub Codespaces secrets to inject certificates
- Or set `GIT_SSL_NO_VERIFY=true` (not recommended)

---

## Team Onboarding

When a new developer joins:

### For the New Developer

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org/GitHub-migrator.git
   cd GitHub-migrator
   ```

2. **Export corporate certificates** (follow Quick Start for your OS above)

3. **Verify setup**:
   ```bash
   ls -la .devcontainer/corporate-certs/
   # Should see your .crt files
   ```

4. **Open in devcontainer**:
   - VS Code: Reopen in Container
   - Wait for build and post-create script

5. **Verify it works**:
   ```bash
   curl -I https://github.com
   go version
   node --version
   ```

### For Documentation Maintainers

Update this file if:
- Certificate export process changes
- New proxy tools are introduced (e.g., new SSL inspection software)
- New OS-specific issues are discovered
- Build process changes

---

## Advanced Configuration

### Custom Certificate Paths

If your organization stores certificates elsewhere:

```bash
# Copy from custom location
cp /path/to/corporate/certs/*.crt .devcontainer/corporate-certs/

# Or create symlinks (not recommended for cross-platform)
ln -s /path/to/certs .devcontainer/corporate-certs
```

### Automated Certificate Export Script

Create `.devcontainer/export-certs.sh`:

```bash
#!/bin/bash
# Automatically export common corporate certificates

mkdir -p .devcontainer/corporate-certs

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    security find-certificate -c "YourCompany Root" -p /Library/Keychains/System.keychain \
      > .devcontainer/corporate-certs/company-root-ca.crt 2>/dev/null
    
    security find-certificate -c "netskope" -p /Library/Keychains/System.keychain \
      > .devcontainer/corporate-certs/netskope-ca.crt 2>/dev/null
fi

# Verify
ls -la .devcontainer/corporate-certs/*.crt
echo "✓ Certificates exported"
```

### Disable SSL Verification (Emergency Only)

**⚠️ NOT RECOMMENDED - Security risk!**

If you need to temporarily bypass SSL for testing:

```json
// devcontainer.json - Add to containerEnv
"containerEnv": {
  "GIT_SSL_NO_VERIFY": "true",
  "NODE_TLS_REJECT_UNAUTHORIZED": "0",
  "GOPROXY": "direct",
  "GOSUMDB": "off"
}
```

---

## Additional Resources

- [OpenSSL Certificate Verification](https://www.openssl.org/docs/man1.1.1/man1/verify.html)
- [Dev Containers Specification](https://containers.dev/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [CA Certificates in Debian](https://wiki.debian.org/Self-Signed_Certificate)

## Need Help?

1. **Check the logs**:
   - VS Code: Output → Dev Containers
   - Docker Desktop: Troubleshoot → View Logs

2. **Verify certificates locally**:
   ```bash
   for cert in .devcontainer/corporate-certs/*.crt; do
     openssl x509 -in "$cert" -text -noout | head -20
   done
   ```

3. **Test Docker build**:
   ```bash
   docker build -f .devcontainer/Dockerfile -t test .
   ```

4. **Contact your IT department** for:
   - Correct certificate names
   - Proxy configuration
   - SSL inspection tool details

---

**Last Updated**: November 2025  
**Maintained by**: DevOps Team  
**Questions?**: Open an issue or contact #devops-help
