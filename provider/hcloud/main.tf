variable "token" {}

variable "hosts" {
  default = 0
}

variable "hostname_format" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "type" {
  type = "string"
}

variable "image" {
  type = "string"
}

variable "ssh_keys" {
  type = "list"
}

provider "hcloud" {
  token = "${var.token}"
}

variable "apt_packages" {
  type    = "list"
  default = []
}

resource "hcloud_server" "host" {
  name        = "${format(var.hostname_format, count.index + 1)}"
  location    = "${var.location}"
  image       = "${var.image}"
  server_type = "${var.type}"
  ssh_keys    = "${var.ssh_keys}"

  count = "${var.hosts}"

  connection {
    user    = "root"
    type    = "ssh"
    timeout = "2m"
    host    = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do sleep 1; done",
      "apt-get update",
      "apt-get install -yq ufw ${join(" ", var.apt_packages)}",
    ]
  }
}

resource "hcloud_network" "net" {
  name     = "kube-net"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_server_subnet" "subnet" {
  network_id   = "${hcloud_network.net.id}"
  type         = "server"
  network_zone = "eu_central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server_network" "network" {
  server_id  = "${element(hcloud_server.host.*.id, count.index)}"
  network_id = "${hcloud_network.net.id}"
  ip         = "${format("10.0.1.%d", count.index + 1)}"

  count = "${var.hosts}"
}

#resource "hcloud_volume" "volume" {
#  name = "${format(var.hostname_format, count.index + 1)}"
#  size = 10
#  server_id =  "${element(hcloud_server.host.*.id, count.index)}"
#  automount = false
#
#  count = "${var.hosts}"
#}

output "hostnames" {
  value = "${hcloud_server.host.*.name}"
}

output "public_ips" {
  value = "${hcloud_server.host.*.ipv4_address}"
}

output "private_ips" {
  value = "${hcloud_server.host.*.ipv4_address}"
}

output "private_network_ips" {
  value = "${hcloud_server_network.network.*.ip}"
}

output "private_network_interface" {
  value = "eth0"
}
