terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "ssh_private_key" {
  description = "Private Key to access the machines"
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_public_key" {
  description = "Public Key to authorized the access for the machines"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "hcloud_token" {
  sensitive = true # Requires terraform = 0.14
}

variable "locations" {
  type = map(string)
  default = {
    "us-east" = "ash-dc1",
    "us-west" = "hil-dc1"
  }
}