terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "wireguard" {
  image              = "ubuntu-22-04-x64"
  name               = var.droplet_name
  region             = var.region
  size               = var.droplet_size
  backups            = false
  monitoring         = true
  ipv6               = false
  ssh_keys           = [var.ssh_key_fingerprint]
  user_data          = file("${path.module}/scripts/setup_wireguard.sh")
  
  tags = ["wireguard", "vpn"]

  vpc_uuid = digitalocean_vpc.wireguard_network.id

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.ssh_private_key_path)
    timeout     = "2m"
  }
}

resource "digitalocean_vpc" "wireguard_network" {
  name        = "wireguard-network"
  region      = var.region
  ip_range    = var.vpc_cidr
}

resource "digitalocean_firewall" "wireguard" {
  name = "wireguard-firewall"

  droplet_ids = [digitalocean_droplet.wireguard.id]

  # Allow SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.allowed_ssh_ips
  }

  # Allow WireGuard UDP traffic
  inbound_rule {
    protocol         = "udp"
    port_range       = var.wireguard_port
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
} 