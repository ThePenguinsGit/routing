resource "hcloud_ssh_key" "admin" {
  name       = "admin"
  public_key = file(var.ssh_public_key)
}

resource "hcloud_primary_ip" "v4" {
  for_each = var.locations
  assignee_type = "server"
  datacenter = each.value
  name = "v4-${each.key}"
  auto_delete   = false
  type          = "ipv4"
}

resource "hcloud_primary_ip" "v6" {
  for_each = var.locations
  assignee_type = "server"
  datacenter = each.value
  name = "v6-${each.key}"
  auto_delete   = false
  type          = "ipv6"
}

resource "hcloud_rdns" "v6" {
  for_each = hcloud_primary_ip.v6
  primary_ip_id  = each.value.id
  ip_address = "${each.value.ip_address}1"
  dns_ptr    = "${each.key}.test.ihatemy.live"
}

resource "hcloud_rdns" "v4" {
  for_each = hcloud_primary_ip.v4
  primary_ip_id  = each.value.id
  ip_address = each.value.ip_address
  dns_ptr    = "${each.key}.test.ihatemy.live"
}

resource "hcloud_server" "proxies" {
  for_each = var.locations
  name = each.key
  datacenter = each.value
  server_type = "cpx11"
  image = "ubuntu-24.04"
  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.v4[each.key].id
    ipv6_enabled = true
    ipv6 = hcloud_primary_ip.v6[each.key].id
  }
  ssh_keys = [hcloud_ssh_key.admin.id]
  provisioner "file" {
    source      = "mc-router"
    destination = "/usr/bin/mc-router"
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ipv4_address
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "file" {
    source      = "mc-router.service"
    destination = "/etc/systemd/system/mc-router.service"
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ipv4_address
      private_key = file(var.ssh_private_key)
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /usr/bin/mc-router",
      "systemctl daemon-reload",
      "systemctl enable --now mc-router",
    ]
    connection {
      type        = "ssh"
      user        = "root"
      host        = self.ipv4_address
      private_key = file(var.ssh_private_key)
    }
  }

}

