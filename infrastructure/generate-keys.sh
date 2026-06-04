#!/bin/bash
# Generate RSA-2048 key pair for JWT RS256 signing
# Run this once before starting docker-compose

set -e

KEYS_DIR="$(cd "$(dirname "$0")" && pwd)/keys"
mkdir -p "$KEYS_DIR"

echo "Generating RSA-2048 key pair..."
openssl genrsa -out "$KEYS_DIR/private-key.pem" 2048
openssl rsa -in "$KEYS_DIR/private-key.pem" -pubout -out "$KEYS_DIR/public-key.pem"

echo "Keys generated in $KEYS_DIR"

# Export as base64-encoded environment variables
echo ""
echo "Add these to your .env file or export them:"
echo ""
echo "JWT_PRIVATE_KEY=$(base64 < "$KEYS_DIR/private-key.pem" | tr -d '\n')"
echo ""
echo "JWT_PUBLIC_KEY=$(base64 < "$KEYS_DIR/public-key.pem" | tr -d '\n')"
