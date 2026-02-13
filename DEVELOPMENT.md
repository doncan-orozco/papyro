# Development Guide

## Local Development Setup

### Basic Setup

```bash
bin/setup
```

### Running the Server

#### Standard HTTP Server

```bash
bin/rails server
```

The application will be available at http://localhost:3000

#### HTTPS Server (SSL/TLS)

For testing features that require HTTPS (like secure cookies, CSRF protection with cross-site settings), you can run the server with SSL enabled.

##### 1. Generate SSL Certificates

First, generate self-signed SSL certificates for localhost:

**Using OpenSSL (recommended for development):**

```bash
mkdir -p config/ssl

openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout config/ssl/localhost-key.pem \
  -out config/ssl/localhost.pem \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,DNS:*.localhost,IP:127.0.0.1"
```

**Using mkcert (alternative method for trusted certificates):**

If you prefer mkcert for better browser trust:

```bash
# Install mkcert
# macOS
brew install mkcert

# Linux
sudo apt install mkcert

# Windows
choco install mkcert

# Create and install local CA
mkcert -install

# Generate certificates
mkdir -p config/ssl
mkcert -key-file config/ssl/localhost-key.pem -cert-file config/ssl/localhost.pem localhost 127.0.0.1 ::1
```

##### 2. Start Server with SSL

Use the provided `bin/dev-ssl` script to start the Rails server with HTTPS enabled:

```bash
# Start on default port 3030
bin/dev-ssl

# Or specify a custom port
bin/dev-ssl 4000
```

The application will be available at https://localhost:3030 (or your specified port)

**Note:** Your browser will show a security warning for self-signed certificates (OpenSSL method). You can:
- Click "Advanced" and "Proceed to localhost" (safe for local development)
- Use mkcert to install a local CA for trusted certificates

##### Alternative: Manual SSL Configuration

If you need more control, you can manually configure SSL using environment variables:

```bash
# Construct the SSL binding URL
CERT_PATH="$(pwd)/config/ssl/localhost.pem"
KEY_PATH="$(pwd)/config/ssl/localhost-key.pem"
BINDING="ssl://127.0.0.1:3030?cert=${CERT_PATH}&key=${KEY_PATH}&verify_mode=none"

# Start the server
BINDING="$BINDING" bin/rails server
```

##### SSL Certificate Management

- SSL certificates are **not** committed to the repository (see `.gitignore`)
- Each developer must generate their own certificates
- Certificates are valid for 10 years (OpenSSL method) or until mkcert CA is removed
- The `config/ssl/` directory is tracked in git, but certificate files (*.pem, *.key) are ignored

### Testing

```bash
bin/rails test
```

### Debugging

#### Session Issues

If you experience session or authentication issues:

1. Clear browser cookies for localhost
2. Ensure SSL certificates are properly generated
3. Check that the server is actually binding to HTTPS (look for `ssl://` in the startup logs)
4. Verify your browser accepted the self-signed certificate

#### SSL Certificate Issues

If the `bin/dev-ssl` script shows "SSL certificates not found":

```bash
# Verify files exist
ls -la config/ssl/

# Regenerate if needed
rm -rf config/ssl/*.pem
# Then run the OpenSSL or mkcert command above
```

#### Testing HTTPS Connection

You can test the HTTPS connection using curl:

```bash
# Test with curl (use -k to skip certificate verification)
curl -k https://localhost:3030/
```

## Additional Resources

- [README.md](README.md) - Project overview
- [docs/README.md](docs/README.md) - Architecture documentation

