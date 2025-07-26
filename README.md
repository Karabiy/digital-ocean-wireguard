# WireGuard VPN on DigitalOcean with Terraform

[![DigitalOcean Referral Badge](https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%201.svg)](https://www.digitalocean.com/?refcode=5dbf01bba8e9&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge)


This project deploys a WireGuard VPN server on a DigitalOcean droplet using Terraform.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v0.12+)
- [DigitalOcean Account](https://m.do.co/c/5dbf01bba8e9)
- DigitalOcean API Token
- SSH key uploaded to DigitalOcean

## SSH Key Generation and Setup

Before configuring Terraform, you need to generate an SSH key pair and upload it to DigitalOcean.

### Generating SSH Keys

#### On Linux/macOS:

1. Open a terminal
2. Generate an SSH key pair:
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```
3. When prompted, press Enter to accept the default file location (`~/.ssh/id_rsa`)
4. Optionally, enter a secure passphrase or press Enter for no passphrase
5. Your public key is now at `~/.ssh/id_rsa.pub` and private key at `~/.ssh/id_rsa`

#### On Windows (using PowerShell):

1. Open PowerShell
2. If not already installed, install OpenSSH:
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
   ```
3. Generate an SSH key pair:
   ```powershell
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
4. When prompted, press Enter to accept the default location (typically `C:\Users\username\.ssh\id_rsa`)
5. Optionally, enter a passphrase
6. Your public key is now at `C:\Users\username\.ssh\id_rsa.pub` and private key at `C:\Users\username\.ssh\id_rsa`

### Uploading SSH Key to DigitalOcean

1. Log in to your DigitalOcean account
2. Go to Settings > Security > SSH Keys
3. Click "Add SSH Key"
4. Copy the contents of your public key file (e.g., `~/.ssh/id_rsa.pub` or `C:\Users\username\.ssh\id_rsa.pub`)
   - On Linux/macOS: `cat ~/.ssh/id_rsa.pub | pbcopy` (macOS) or `cat ~/.ssh/id_rsa.pub | xclip -selection clipboard` (Linux)
   - On Windows: `Get-Content C:\Users\username\.ssh\id_rsa.pub | Set-Clipboard`
5. Paste the key into the "SSH key content" field
6. Give the key a name (e.g., "My Laptop")
7. Click "Add SSH Key"

### Getting Your SSH Key Fingerprint

After adding your SSH key to DigitalOcean, you'll need the fingerprint for the Terraform configuration:

1. In DigitalOcean, go to Settings > Security > SSH Keys
2. Find your SSH key in the list
3. The fingerprint is displayed in the "Fingerprint" column (format: `xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx`)
4. Copy this fingerprint for use in your `terraform.tfvars` file

## Configuration

1. Create a `terraform.tfvars` file with your DigitalOcean API token and SSH key information:

```hcl
do_token             = "your_digitalocean_api_token"
ssh_key_fingerprint  = "your_ssh_key_fingerprint"
ssh_private_key_path = "~/.ssh/id_rsa" # Path to your private SSH key
allowed_ssh_ips      = ["your.public.ip.address/32"] # Your IP address for SSH access
```

2. Customize other variables as needed in the `variables.tf` file or in your `terraform.tfvars` file.

## Deployment

1. Initialize Terraform:
```bash
terraform init
```

2. Preview the changes:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. After deployment, Terraform will output:
   - The WireGuard server's public IP address
   - The WireGuard port (default: 51820)
   - Instructions for retrieving client configurations

## Client Configuration

1. SSH into the server:
```bash
ssh -i ~/.ssh/id_rsa root@<server_ip>
```

2. Verify that WireGuard is properly installed and running:
```bash
systemctl status wg-quick@wg0
```

3. Client configurations should be located in `/root/wireguard-clients/`:
```bash
ls -la /root/wireguard-clients/
```

4. Copy the client configuration to your local machine:
```bash
scp -i ~/.ssh/id_rsa root@<server_ip>:/root/wireguard-clients/client1.conf .
```

5. Import the configuration into your WireGuard client:
   - For mobile: Scan the QR code
   - For desktop: Import the .conf file

## Adding More Clients

There are two ways to add more clients:

### Option 1: Using Terraform (Recommended)

Increase the `wireguard_clients` variable in `terraform.tfvars` and run `terraform apply` again. This will recreate the droplet with the new configuration.

```hcl
wireguard_clients = 3  # Creates 3 client configurations
```

### Option 2: Manually on the Server

If you don't want to recreate the droplet, you can manually add clients using the included `add_config.sh` script:

1. SSH into the server:
```bash
ssh -i ~/.ssh/id_rsa root@<server_ip>
```

2. Upload the add_config.sh script to the server:
```bash
scp -i ~/.ssh/id_rsa scripts/add_config.sh root@<server_ip>:/root/
```

3. Make the script executable:
```bash
ssh -i ~/.ssh/id_rsa root@<server_ip> "chmod +x /root/add_config.sh"
```

4. Run the script with the client number you want to add:
```bash
ssh -i ~/.ssh/id_rsa root@<server_ip> "/root/add_config.sh 1"  # For client 1
ssh -i ~/.ssh/id_rsa root@<server_ip> "/root/add_config.sh 2"  # For client 2
# etc.
```

5. Copy the client configuration to your local machine:
```bash
scp -i ~/.ssh/id_rsa root@<server_ip>:/root/wireguard-clients/client1.conf .
```

## Troubleshooting

### WireGuard Service Not Found

If you see `Unit wg-quick@wg0.service could not be found`, WireGuard may not be properly installed:

1. SSH into the server:
```bash
ssh -i ~/.ssh/id_rsa root@<server_ip>
```

2. Upload the setup_wireguard.sh script to the server:
```bash
scp -i ~/.ssh/id_rsa scripts/setup_wireguard.sh root@<server_ip>:/root/
```

3. Make the script executable and run it:
```bash
ssh -i ~/.ssh/id_rsa root@<server_ip> "chmod +x /root/setup_wireguard.sh && /root/setup_wireguard.sh"
```

### Client Configuration Directory is Empty

If the `/root/wireguard-clients/` directory is empty, the setup script likely didn't complete. Use the `add_config.sh` script to generate client configurations as described in the "Adding More Clients" section.

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Security Considerations

- By default, SSH access is allowed from any IP address. For better security, restrict the `allowed_ssh_ips` variable to your specific IP address.
- All WireGuard traffic is encrypted, but consider additional security measures as needed.
- Regularly update your server for security patches. 
