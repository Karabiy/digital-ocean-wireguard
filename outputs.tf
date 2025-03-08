output "wireguard_public_ip" {
  description = "Public IP address of the WireGuard server"
  value       = digitalocean_droplet.wireguard.ipv4_address
}

output "wireguard_port" {
  description = "WireGuard port"
  value       = var.wireguard_port
}

output "instructions" {
  description = "Instructions for accessing client configurations"
  value       = <<-EOT
    Your WireGuard server has been deployed!
    
    Server IP: ${digitalocean_droplet.wireguard.ipv4_address}
    WireGuard Port: ${var.wireguard_port}
    
    === NORMAL SETUP ===
    
    To retrieve client configurations:
    1. SSH into the server: ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address}
    2. Verify WireGuard is running: systemctl status wg-quick@wg0
    3. Check for client configs: ls -la /root/wireguard-clients/
    4. Copy the client configuration files using SCP:
       scp -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address}:/root/wireguard-clients/client*.conf .
    
    Import the .conf file to your WireGuard client application to connect.
    
    === TROUBLESHOOTING ===
    
    If client configurations are missing or WireGuard isn't properly installed, you can fix it:
    
    1. Upload the included scripts to the server:
       scp -i ${var.ssh_private_key_path} scripts/setup_wireguard.sh root@${digitalocean_droplet.wireguard.ipv4_address}:/root/
       scp -i ${var.ssh_private_key_path} scripts/add_config.sh root@${digitalocean_droplet.wireguard.ipv4_address}:/root/
       
    2. Make the scripts executable:
       ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address} "chmod +x /root/*.sh"
       
    3. If WireGuard is not installed, run the setup script:
       ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address} "/root/setup_wireguard.sh"
       
    4. Generate client configurations:
       ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address} "/root/add_config.sh 1"  # For client 1
       ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address} "/root/add_config.sh 2"  # For client 2
       
    5. Download the client configuration files:
       scp -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wireguard.ipv4_address}:/root/wireguard-clients/client*.conf .
  EOT
} 