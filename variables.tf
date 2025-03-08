variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_fingerprint" {
  description = "Fingerprint of the public SSH key to be used for the droplet"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the private SSH key for connecting to the droplet"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "droplet_name" {
  description = "Name of the DigitalOcean droplet"
  type        = string
  default     = "wireguard-vpn"
}

variable "region" {
  description = "DigitalOcean region for the droplet"
  type        = string
  default     = "nyc1"
}

variable "droplet_size" {
  description = "Size of the DigitalOcean droplet"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH into the droplet"
  type        = list(string)
  default     = ["0.0.0.0/0"] # You should restrict this to your own IP address
}

variable "wireguard_port" {
  description = "UDP port for WireGuard"
  type        = string
  default     = "51820"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.10.0/24"
}

variable "wireguard_clients" {
  description = "Number of WireGuard client configurations to generate"
  type        = number
  default     = 1
}

variable "wireguard_network" {
  description = "Internal network CIDR for WireGuard"
  type        = string
  default     = "10.77.88.0/24"
} 