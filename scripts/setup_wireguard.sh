#!/bin/bash
set -e

# Variables - these will be accessible as instance meta-data
WIREGUARD_PORT=51820
WIREGUARD_NETWORK="10.77.88.0/24"
CLIENT_COUNT=1

# Update system
apt-get update
apt-get upgrade -y

# Install WireGuard and required packages
apt-get install -y wireguard wireguard-tools qrencode

# Enable IP forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Get public IP address
PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)

# Generate server private key
umask 077
mkdir -p /etc/wireguard/
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key

SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)

# Create server config
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.77.88.1/24
PrivateKey = ${SERVER_PRIVATE_KEY}
ListenPort = ${WIREGUARD_PORT}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF

# Enable WireGuard service
systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service

# Create directory for client configs
mkdir -p /root/wireguard-clients

# Generate client configurations
for i in $(seq 1 $CLIENT_COUNT); do
    # Generate client keys
    CLIENT_PRIVATE_KEY=$(wg genkey)
    CLIENT_PUBLIC_KEY=$(echo "${CLIENT_PRIVATE_KEY}" | wg pubkey)
    
    # Assign client IP
    CLIENT_IP="10.77.88.$((i+1))/32"
    
    # Add client to server config
    cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${CLIENT_IP}
EOF
    
    # Create client config
    cat > /root/wireguard-clients/client${i}.conf << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${PUBLIC_IP}:${WIREGUARD_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
    
    # Generate QR code for client config
    qrencode -t png -o /root/wireguard-clients/client${i}.png -r /root/wireguard-clients/client${i}.conf
done

# Apply changes to WireGuard
systemctl restart wg-quick@wg0.service

# Set permissions
chmod -R 600 /root/wireguard-clients/
chmod -R 600 /etc/wireguard/

# Output success message
echo "WireGuard installation completed successfully!"
echo "Client configurations are available in /root/wireguard-clients/" 