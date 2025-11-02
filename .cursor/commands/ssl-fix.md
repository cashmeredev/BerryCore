# SSL Certificate Fix for qpkg

## The Problem
User's curl was looking for missing SSL certificates from old `clitools`:
```
error setting certificate verify locations: 
  CAfile: /accounts/1000/shared/misc/clitools/ssl/cert.pem
```

## ✅ FIXED in Latest Version
The new berrycore.zip has all curl commands using `-k` flag to bypass SSL verification.

## 🔧 Quick Fix for Current Users

### Option 1: Tell curl to ignore SSL certs (temporary)
```bash
# Create a curl config file
echo "insecure" > ~/.curlrc

# Test it
curl "https://raw.githubusercontent.com/sw7ft/BerryCore/main/ports/INDEX"
```

### Option 2: Update their qpkg immediately
```bash
cd /accounts/1000/shared/misc/berrycore/bin

# Download fixed qpkg
curl -k -o qpkg "https://raw.githubusercontent.com/sw7ft/BerryCore/main/berrycore/bin/qpkg"

# Make executable
chmod +x qpkg

# Test it
qpkg ports
```

### Option 3: Unset the bad SSL env vars
```bash
# Check if these exist
echo $CURL_CA_BUNDLE
echo $SSL_CERT_FILE

# If they point to clitools, unset them
unset CURL_CA_BUNDLE
unset SSL_CERT_FILE

# Add to profile to make permanent
echo "unset CURL_CA_BUNDLE" >> ~/.profile
echo "unset SSL_CERT_FILE" >> ~/.profile
```

### Option 4: Manual package install (bypass qpkg)
```bash
cd $NATIVE_TOOLS

# Download with -k flag
curl -k -L -O "https://raw.githubusercontent.com/sw7ft/BerryCore/main/ports/net-hydra-9.5.zip"

# Extract
unzip -o net-hydra-9.5.zip

# Set permissions
chmod +x bin/*

# Clean up
rm net-hydra-9.5.zip
```

## Verification
After applying any fix:
```bash
# Should show the ports list
qpkg ports

# Should work without errors
curl -I https://github.com
```


