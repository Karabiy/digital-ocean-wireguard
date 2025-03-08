cat > /root/add_wireguard_client.sh << 'EOF'
#!/bin/bash
set -e

# Check if WireGuard is installed
if ! command -v wg &> /dev/null; then
    echo "WireGuard is not installed. Please install it first."
    exit 1
fi

# Check if wg0.conf exists
if [ ! -f /etc/wireguard/wg0.conf ]; then
    echo "WireGuard configuration not found. Run the full setup script first."
    exit 1
fi

# Check if a client number was provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <client_number>"
    exit 1
fi

CLIENT_NUM=$1
WIREGUARD_PORT=51820

# Get server's public key or create if it doesn't exist
if [ -f /etc/wireguard/server_public.key ]; then
    SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
else
    echo "Server public key not found. Generating new server keys..."
    wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
    SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
fi

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)

# Generate client keys
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "${CLIENT_PRIVATE_KEY}" | wg pubkey)

# Assign client IP
CLIENT_IP="10.77.88.$((CLIENT_NUM+1))/32"

# Add client to server config
cat >> /etc/wireguard/wg0.conf << EOF2

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_IP}
EOF2

# Create client config directory if it doesn't exist
mkdir -p /root/wireguard-clients/

# Create client config
cat > /root/wireguard-clients/client${CLIENT_NUM}.conf << EOF2
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${PUBLIC_IP}:${WIREGUARD_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF2

# Generate QR code for client config
if command -v qrencode &> /dev/null; then
    qrencode -t png -o /root/wireguard-clients/client${CLIENT_NUM}.png -r /root/wireguard-clients/client${CLIENT_NUM}.conf
fi

# Apply changes to WireGuard if running
if systemctl is-active --quiet wg-quick@wg0; then
    wg syncconf wg0 <(wg-quick strip wg0)
else
    echo "WireGuard service not running. Starting it now..."
    systemctl enable wg-quick@wg0.service
    systemctl start wg-quick@wg0.service
fi

# Set permissions
chmod -R 600 /root/wireguard-clients/
chmod -R 600 /etc/wireguard/

echo "Client ${CLIENT_NUM} configuration created in /root/wireguard-clients/client${CLIENT_NUM}.conf"
EOF

chmod +x /root/add_wireguard_client.sh