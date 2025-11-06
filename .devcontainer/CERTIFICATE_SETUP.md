# Corporate SSL Certificate Setup for DevContainer

This guide provides detailed instructions for configuring corporate SSL certificates in the GitHub Migrator DevContainer environment. If your organization uses SSL inspection proxies (like Netskope, Zscaler, Cisco Umbrella, etc.), you must follow these steps before building the DevContainer.

## Table of Contents

- [Overview](#overview)
- [When Do You Need This?](#when-do-you-need-this)
- [Quick Reference](#quick-reference)
- [Windows Setup](#windows-setup)
- [macOS Setup](#macos-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Overview

Corporate SSL inspection proxies intercept HTTPS traffic by presenting their own certificates instead of the original website certificates. For the DevContainer to successfully download dependencies and communicate with external services, it needs to trust these corporate certificates.

### How It Works

1. You export corporate certificates from your host system
2. Place certificates in `.devcontainer/corporate-certs/`
3. The Dockerfile copies and installs them during container build
4. All tools (Go, Node.js, Git, curl, etc.) trust the certificates

## When Do You Need This?

You need to set up corporate certificates if:

- ✅ You're behind a corporate proxy with SSL inspection
- ✅ You see SSL/TLS certificate verification errors when downloading packages
- ✅ `curl` or `wget` commands fail with certificate errors
- ✅ Go module downloads fail with certificate validation errors
- ✅ npm/Node.js package installations fail with certificate errors
- ✅ Git operations over HTTPS fail with SSL errors

You **don't** need this if:

- ❌ You're working from home without a corporate VPN
- ❌ You're on a network without SSL inspection
- ❌ Your organization doesn't intercept HTTPS traffic

## Quick Reference

### Windows PowerShell (Run as Administrator)

```powershell
# Create directory
New-Item -Path ".devcontainer\corporate-certs" -ItemType Directory -Force

# List all root certificates
Get-ChildItem -Path Cert:\CurrentUser\Root | Select-Object Subject, Thumbprint

# Export specific certificate (replace Thumbprint)
$cert = Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object {$_.Thumbprint -eq "YOUR_THUMBPRINT"}
[System.IO.File]::WriteAllBytes(".devcontainer\corporate-certs\corporate-root.crt", $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
```

### macOS Terminal

```bash
# Create directory
mkdir -p .devcontainer/corporate-certs

# List all certificates
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain
security find-certificate -a -p /Library/Keychains/System.keychain

# Export specific certificate
security find-certificate -c "Your Certificate Name" -a -p > .devcontainer/corporate-certs/corporate-root.crt
```

---

## Windows Setup

### Step 1: Identify Corporate Certificates

#### Method A: Using PowerShell (Recommended)

1. **Open PowerShell as Administrator:**

   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **List all certificates in the Trusted Root store:**

   ```powershell
   Get-ChildItem -Path Cert:\CurrentUser\Root | Select-Object Subject, Issuer, Thumbprint, FriendlyName | Format-Table -AutoSize
   ```

3. **Look for your organization's certificates.** Common names include:

   - Netskope
   - Zscaler
   - Cisco Umbrella
   - Your company name
   - "Root CA" or "Intermediate CA"

4. **Note the certificate's Subject or Thumbprint** for export.

#### Method B: Using Certificate Manager GUI

1. **Open Certificate Manager:**

   - Press `Win + R`
   - Type: `certmgr.msc`
   - Press Enter

2. **Navigate to certificates:**

   - Expand "Trusted Root Certification Authorities"
   - Click "Certificates"

3. **Find corporate certificates:**
   - Look for certificates issued by your organization or proxy vendor
   - Double-click to view details

### Step 2: Export Certificates

#### Method A: PowerShell Export (Recommended)

1. **Create the certificate directory:**

   ```powershell
   New-Item -Path ".devcontainer\corporate-certs" -ItemType Directory -Force
   ```

2. **Export by certificate name/subject:**

   ```powershell
   # Replace "Netskope" with your certificate's subject
   $cert = Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object {$_.Subject -like "*Netskope*"}
   [System.IO.File]::WriteAllBytes(".devcontainer\corporate-certs\netskope-root.crt", $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
   ```

3. **Export by thumbprint (more precise):**

   ```powershell
   # Replace with your certificate's thumbprint
   $cert = Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object {$_.Thumbprint -eq "1234567890ABCDEF1234567890ABCDEF12345678"}
   [System.IO.File]::WriteAllBytes(".devcontainer\corporate-certs\corporate-root.crt", $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
   ```

4. **Export multiple certificates:**
   ```powershell
   # Export all certificates matching a pattern
   Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object {$_.Subject -like "*YourCompany*"} | ForEach-Object {
       $filename = ".devcontainer\corporate-certs\$($_.FriendlyName -replace '[^a-zA-Z0-9]','-').crt"
       [System.IO.File]::WriteAllBytes($filename, $_.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
       Write-Host "Exported: $filename"
   }
   ```

#### Method B: GUI Export

1. **Open Certificate Manager** (`certmgr.msc`)

2. **Navigate to the certificate:**

   - Trusted Root Certification Authorities → Certificates
   - Find your corporate certificate

3. **Export the certificate:**
   - Right-click the certificate
   - Select "All Tasks" → "Export"
   - Click "Next" in the Certificate Export Wizard
   - Select "DER encoded binary X.509 (.CER)"
   - Click "Next"
   - Save to: `.devcontainer\corporate-certs\certificate-name.crt`
   - Click "Next" then "Finish"

**Note:** Rename `.cer` files to `.crt` if needed:

```powershell
Rename-Item ".devcontainer\corporate-certs\certificate.cer" -NewName "certificate.crt"
```

### Step 3: Verify Export (Windows)

```powershell
# List exported certificates
Get-ChildItem -Path ".devcontainer\corporate-certs\" -Filter "*.crt"

# View certificate details
Get-Content ".devcontainer\corporate-certs\corporate-root.crt" -Raw
```

You should see PEM-encoded certificate data starting with:

```
-----BEGIN CERTIFICATE-----
```

If you see binary data, convert it:

```powershell
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(".devcontainer\corporate-certs\binary-cert.crt")
$pemCert = "-----BEGIN CERTIFICATE-----`n" + [Convert]::ToBase64String($cert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks) + "`n-----END CERTIFICATE-----"
Set-Content -Path ".devcontainer\corporate-certs\corporate-root.crt" -Value $pemCert
```

---

## macOS Setup

### Step 1: Identify Corporate Certificates

#### Method A: Using Keychain Access GUI

1. **Open Keychain Access:**

   - Press `Cmd + Space`
   - Type: "Keychain Access"
   - Press Enter

2. **Select the appropriate keychain:**

   - Click "System" in the left sidebar (for system-wide certificates)
   - Or click "login" (for user-specific certificates)

3. **Find corporate certificates:**

   - Look in the "Certificates" category
   - Search for your organization name or proxy vendor (Netskope, Zscaler, etc.)
   - Corporate certificates often have "Root CA" or your company name in the title

4. **Note the certificate name** (you'll use this for export)

#### Method B: Using Terminal

1. **List all system certificates:**

   ```bash
   security find-certificate -a -p /Library/Keychains/System.keychain
   ```

2. **List all user certificates:**

   ```bash
   security find-certificate -a -p ~/Library/Keychains/login.keychain-db
   ```

3. **Search for specific certificates:**
   ```bash
   # Search for certificates containing "Netskope"
   security find-certificate -a -c "Netskope" /Library/Keychains/System.keychain
   ```

### Step 2: Export Certificates

#### Method A: Terminal Export (Recommended)

1. **Create the certificate directory:**

   ```bash
   mkdir -p .devcontainer/corporate-certs
   ```

2. **Export by certificate name:**

   ```bash
   # Replace "Netskope" with your certificate's common name
   security find-certificate -c "Netskope" -a -p > .devcontainer/corporate-certs/netskope-root.crt
   ```

3. **Export from specific keychain:**

   ```bash
   # From System keychain
   security find-certificate -c "Your Corp Root CA" -a -p /Library/Keychains/System.keychain > .devcontainer/corporate-certs/corp-root.crt

   # From login keychain
   security find-certificate -c "Your Corp Root CA" -a -p ~/Library/Keychains/login.keychain-db > .devcontainer/corporate-certs/corp-root.crt
   ```

4. **Export multiple certificates:**

   ```bash
   # Export all certificates matching a pattern
   for cert_name in "Netskope Root CA" "Company Intermediate CA"; do
       filename=$(echo "$cert_name" | tr '[:upper:] ' '[:lower:]-')
       security find-certificate -c "$cert_name" -a -p > ".devcontainer/corporate-certs/${filename}.crt"
       echo "Exported: ${filename}.crt"
   done
   ```

5. **Export by SHA-1 fingerprint:**

   ```bash
   # First, find the certificate's SHA-1
   security find-certificate -a -Z /Library/Keychains/System.keychain | grep -A 1 "Netskope"

   # Then export using the hash
   security find-certificate -Z -p -a /Library/Keychains/System.keychain | \
       awk '/^SHA-1 hash: YOUR_HASH/{p=1} p&&/-----BEGIN/{print; f=1} f' | \
       awk '/-----END/{print; exit} {print}' > .devcontainer/corporate-certs/cert.crt
   ```

#### Method B: Keychain Access GUI Export

1. **Open Keychain Access** (`Cmd + Space` → "Keychain Access")

2. **Select the keychain:**

   - Click "System" or "login" in the left sidebar

3. **Find and select your corporate certificate**

4. **Export the certificate:**
   - Right-click the certificate
   - Select "Export [Certificate Name]..."
   - File Format: Select "Privacy Enhanced Mail (.pem)"
   - Save location: `.devcontainer/corporate-certs/`
   - Name: `corporate-root.crt`
   - Click "Save"
   - Enter your macOS password if prompted

**Note:** If you exported as `.pem`, rename to `.crt`:

```bash
mv .devcontainer/corporate-certs/certificate.pem .devcontainer/corporate-certs/certificate.crt
```

### Step 3: Verify Export (macOS)

```bash
# List exported certificates
ls -lh .devcontainer/corporate-certs/

# View certificate details
openssl x509 -in .devcontainer/corporate-certs/corporate-root.crt -text -noout

# Verify certificate format
head -n 1 .devcontainer/corporate-certs/corporate-root.crt
```

You should see output starting with:

```
-----BEGIN CERTIFICATE-----
```

---

## Verification

### Before Building the Container

Verify certificates are in the correct location:

```bash
# Unix/macOS/Linux
ls -la .devcontainer/corporate-certs/

# Windows PowerShell
Get-ChildItem -Path ".devcontainer\corporate-certs\" -Recurse
```

Expected output:

```
corporate-certs/
├── netskope-root.crt
├── company-intermediate.crt
└── corp-proxy.crt
```

### After Building the Container

Once the DevContainer is built and running:

1. **Check certificates are installed:**

   ```bash
   ls -la /usr/local/share/ca-certificates/corporate/
   ```

2. **Verify certificates in bundle:**

   ```bash
   grep -r "BEGIN CERTIFICATE" /usr/local/share/ca-certificates/corporate/
   ```

3. **Test certificate trust:**

   ```bash
   # Test with curl (replace with your corporate domain)
   curl -v https://github.com

   # Test with Go
   go env -w GOPRIVATE=""
   go get -v github.com/google/uuid@latest

   # Test with npm
   npm config get cafile
   npm install --dry-run express
   ```

4. **Check environment variables:**
   ```bash
   echo $SSL_CERT_FILE
   echo $CURL_CA_BUNDLE
   echo $NODE_EXTRA_CA_CERTS
   ```

Expected output:

```
/etc/ssl/certs/ca-certificates.crt
/etc/ssl/certs/ca-certificates.crt
/etc/ssl/certs/ca-certificates.crt
```

---

## Troubleshooting

### Certificate Errors Still Occur

**Problem:** Still seeing SSL certificate verification errors after setup.

**Solutions:**

1. **Verify certificate format:**

   ```bash
   # Check if certificate is PEM format
   head -n 1 .devcontainer/corporate-certs/*.crt
   ```

   Should show: `-----BEGIN CERTIFICATE-----`

2. **Check for multiple certificates in chain:**
   You may need to export both root and intermediate certificates:

   ```bash
   # Count certificates in file
   grep -c "BEGIN CERTIFICATE" .devcontainer/corporate-certs/your-cert.crt
   ```

3. **Rebuild without cache:**
   ```bash
   # In VS Code: Ctrl+Shift+P (Cmd+Shift+P on macOS)
   # Run: "Dev Containers: Rebuild Container Without Cache"
   ```

### Certificate Not Found During Export

**Problem:** Can't find corporate certificate in your system.

**Solutions:**

1. **Windows - Check all certificate stores:**

   ```powershell
   # Check Current User store
   Get-ChildItem -Path Cert:\CurrentUser\Root

   # Check Local Machine store (run as Admin)
   Get-ChildItem -Path Cert:\LocalMachine\Root

   # Check Intermediate Certificates
   Get-ChildItem -Path Cert:\CurrentUser\CA
   ```

2. **macOS - Check all keychains:**

   ```bash
   # System keychain
   security find-certificate -a /Library/Keychains/System.keychain

   # User login keychain
   security find-certificate -a ~/Library/Keychains/login.keychain-db

   # System Roots
   security find-certificate -a /System/Library/Keychains/SystemRootCertificates.keychain
   ```

3. **Contact your IT department:**
   - Ask for the corporate root CA certificate file
   - They may provide it as `.cer`, `.pem`, or `.crt` format

### Wrong Certificate Format

**Problem:** Certificate is in DER/binary format instead of PEM.

**Solution - Convert to PEM:**

```bash
# Using openssl (available on macOS/Linux, or Git Bash on Windows)
openssl x509 -inform DER -in certificate.cer -out certificate.crt -outform PEM

# Verify conversion
file certificate.crt
# Should output: "PEM certificate"
```

### Build Fails During Certificate Installation

**Problem:** Dockerfile fails when copying certificates.

**Solutions:**

1. **Check directory exists:**

   ```bash
   mkdir -p .devcontainer/corporate-certs
   ```

2. **Verify file permissions:**

   ```bash
   # Unix/macOS
   chmod 644 .devcontainer/corporate-certs/*.crt

   # Windows PowerShell
   icacls ".devcontainer\corporate-certs\*.crt" /grant Everyone:R
   ```

3. **Check file extensions:**
   Only `.crt` files are copied. Rename if needed:

   ```bash
   # Rename .pem to .crt
   mv cert.pem cert.crt

   # Rename .cer to .crt
   mv cert.cer cert.crt
   ```

### Git Still Fails with SSL Errors

**Problem:** Git operations fail despite certificates being installed.

**Solutions:**

1. **Check git configuration:**

   ```bash
   git config --global --get http.sslCAInfo
   # Should output: /etc/ssl/certs/ca-certificates.crt
   ```

2. **Manually configure git:**

   ```bash
   git config --global http.sslCAInfo /etc/ssl/certs/ca-certificates.crt
   git config --global http.sslVerify true
   ```

3. **Verify post-create script ran:**
   ```bash
   cat ~/.gitconfig
   ```

### Go Module Downloads Fail

**Problem:** `go get` or `go mod download` fails with certificate errors.

**Solutions:**

1. **Verify Go environment:**

   ```bash
   go env | grep -i proxy
   go env | grep -i sum
   ```

2. **Set Go proxy explicitly:**

   ```bash
   go env -w GOPROXY=https://proxy.golang.org,direct
   go env -w GOSUMDB=sum.golang.org
   ```

3. **Test with verbose output:**
   ```bash
   go get -v -x github.com/google/uuid@latest
   ```

### npm/Node.js Certificate Errors

**Problem:** npm install fails with SSL errors.

**Solutions:**

1. **Verify Node environment:**

   ```bash
   echo $NODE_EXTRA_CA_CERTS
   # Should output: /etc/ssl/certs/ca-certificates.crt
   ```

2. **Configure npm explicitly:**

   ```bash
   npm config set cafile /etc/ssl/certs/ca-certificates.crt
   npm config set strict-ssl true
   ```

3. **Test npm configuration:**
   ```bash
   npm config get cafile
   npm config get strict-ssl
   ```

---

## Advanced Configuration

### Using Environment-Specific Certificates

If you work in multiple environments (office, home, VPN), you can maintain separate certificate sets:

**Directory structure:**

```
.devcontainer/
└── corporate-certs/
    ├── office/
    │   ├── office-root.crt
    │   └── office-proxy.crt
    ├── vpn/
    │   └── vpn-root.crt
    └── current -> office/  # Symlink to active set
```

**Setup:**

```bash
# macOS/Linux
ln -sf office .devcontainer/corporate-certs/current

# Windows (PowerShell, run as Admin)
New-Item -ItemType SymbolicLink -Path ".devcontainer\corporate-certs\current" -Target "office"
```

### Certificate Chain Files

If you have a full certificate chain in one file:

1. **Verify chain:**

   ```bash
   # Count certificates
   grep -c "BEGIN CERTIFICATE" chain.crt
   ```

2. **Split if needed:**

   ```bash
   # Split chain into individual files
   csplit -f cert- -b %02d.crt chain.crt '/-----BEGIN CERTIFICATE-----/' '{*}'

   # Move to corporate-certs
   mv cert-*.crt .devcontainer/corporate-certs/
   ```

3. **Or use the chain as-is:**
   ```bash
   cp chain.crt .devcontainer/corporate-certs/corporate-chain.crt
   ```

### Automated Certificate Export

**macOS - Create a script:**

```bash
#!/bin/bash
# export-certs.sh

CERT_DIR=".devcontainer/corporate-certs"
CERT_NAMES=("Netskope Root CA" "Company Intermediate CA")

mkdir -p "$CERT_DIR"

for cert in "${CERT_NAMES[@]}"; do
    filename=$(echo "$cert" | tr '[:upper:] ' '[:lower:]-')
    echo "Exporting: $cert"
    security find-certificate -c "$cert" -a -p > "$CERT_DIR/${filename}.crt"
done

echo "✓ Certificate export complete"
ls -lh "$CERT_DIR"
```

**Windows - Create a PowerShell script:**

```powershell
# export-certs.ps1

$certDir = ".devcontainer\corporate-certs"
$certSubjects = @("*Netskope*", "*YourCompany*")

New-Item -Path $certDir -ItemType Directory -Force | Out-Null

foreach ($subject in $certSubjects) {
    Get-ChildItem -Path Cert:\CurrentUser\Root | Where-Object {$_.Subject -like $subject} | ForEach-Object {
        $filename = "$certDir\$($_.FriendlyName -replace '[^a-zA-Z0-9]','-').crt"
        [System.IO.File]::WriteAllBytes($filename, $_.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
        Write-Host "✓ Exported: $filename"
    }
}

Get-ChildItem -Path $certDir
```

### Corporate Proxy Configuration

If you also need to configure proxy settings:

1. **Set proxy environment variables** (already configured in `devcontainer.json`):

   ```json
   "remoteEnv": {
     "HTTP_PROXY": "${localEnv:HTTP_PROXY}",
     "HTTPS_PROXY": "${localEnv:HTTPS_PROXY}",
     "NO_PROXY": "${localEnv:NO_PROXY}"
   }
   ```

2. **Set on host before opening container:**

   ```bash
   # macOS/Linux
   export HTTP_PROXY=http://proxy.company.com:8080
   export HTTPS_PROXY=http://proxy.company.com:8080
   export NO_PROXY=localhost,127.0.0.1,.company.com

   # Windows PowerShell
   $env:HTTP_PROXY="http://proxy.company.com:8080"
   $env:HTTPS_PROXY="http://proxy.company.com:8080"
   $env:NO_PROXY="localhost,127.0.0.1,.company.com"
   ```

---

## Security Notes

### Certificate Privacy

- ⚠️ **Corporate certificates are in `.gitignore`** - they will not be committed to version control
- ✅ Safe to have certificates in your local `.devcontainer/corporate-certs/` directory
- ❌ **Never commit certificates to public repositories**
- ✅ Corporate certificates are typically public keys (safe to share within organization)

### Best Practices

1. **Keep certificates updated:** Export fresh certificates if they're rotated by IT
2. **Use read-only permissions:** Prevent accidental modification
3. **Document certificate sources:** Note where each certificate came from
4. **Verify before trusting:** Ensure certificates are from legitimate sources

---

## Support

### Getting Help

1. **Check container build logs:**

   ```
   View → Command Palette → "Dev Containers: Show Container Log"
   ```

2. **Verify certificate installation:**

   ```bash
   update-ca-certificates --verbose
   ```

3. **Contact your IT department** if:
   - You cannot locate corporate certificates
   - You need specific proxy configurations
   - You need additional security policies

### Additional Resources

- [Docker DevContainer Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [OpenSSL Certificate Commands](https://www.openssl.org/docs/man1.1.1/man1/x509.html)
- [Git SSL Configuration](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpsslCAInfo)
- [Node.js TLS/SSL](https://nodejs.org/api/tls.html)

---

## Summary

### Quick Checklist

- [ ] Identified corporate certificate(s) on your system
- [ ] Created `.devcontainer/corporate-certs/` directory
- [ ] Exported certificate(s) to the directory in `.crt` format
- [ ] Verified certificates are PEM-encoded (start with `-----BEGIN CERTIFICATE-----`)
- [ ] Built/rebuilt the DevContainer
- [ ] Verified certificate installation in container
- [ ] Tested SSL connections (curl, git, go, npm)

### Common Commands Reference

| Task               | Windows                                 | macOS                                               |
| ------------------ | --------------------------------------- | --------------------------------------------------- |
| List certificates  | `Get-ChildItem Cert:\CurrentUser\Root`  | `security find-certificate -a`                      |
| Export certificate | `Export-Certificate -FilePath cert.crt` | `security find-certificate -c "Name" -p > cert.crt` |
| Verify format      | `Get-Content cert.crt`                  | `head -n 1 cert.crt`                                |
| Test SSL           | `curl -v https://github.com`            | `curl -v https://github.com`                        |

---

For questions or issues with certificate setup, please refer to the [Troubleshooting](#troubleshooting) section or contact your organization's IT support.
