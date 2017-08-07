provider "opc" {
  user = "${var.user}"
  password = "${var.password}"
  identity_domain = "${var.domain}"
  endpoint = "${var.endpoint}"
}

resource "opc_compute_ssh_key" "ssh_key" {
  name = "mysql-example-key"
  key = "${file(var.ssh_public_key)}"
  enabled = true
}


resource "opc_compute_vnic_set" "nat_set" {
  name         = "nat_vnic_set"
  description  = "NAT vnic set"
}

resource "opc_compute_vnic_set" "mysql_01" {
  name         = "mysql_01"
  description  = "MySQL 01 vnic set"
}

resource "opc_compute_vnic_set" "mysql_02" {
  name         = "mysql_02"
  description  = "MySQL 02 vnic set"
}

resource "opc_compute_route" "nat_route" {
  name              = "nat_route"
  description       = "NAT IP Network route"
  admin_distance    = 1
  ip_address_prefix = "0.0.0.0/0"
  next_hop_vnic_set = "${opc_compute_vnic_set.nat_set.name}"
}

resource "opc_compute_route" "mysql_vip_route" {
  name              = "mysql_vip"
  description       = "MySQL VIP Network route"
  admin_distance    = 0
  ip_address_prefix = "192.168.2.88/32"
  next_hop_vnic_set = "${opc_compute_vnic_set.mysql_01.name}"
}

data "template_file" "mysql1_sh" {
  template = "${file("templates/mysql.sh.tpl")}"

  vars {
    mysql_vip_route = "/Compute-${var.domain}/${var.user}/${opc_compute_route.mysql_vip_route.name}"
    mysql_vnset = "/Compute-${var.domain}/${var.user}/${opc_compute_vnic_set.mysql_02.name}"
  }
}

data "template_file" "mysql2_sh" {
  template = "${file("templates/mysql.sh.tpl")}"

  vars {
    mysql_vip_route = "/Compute-${var.domain}/${var.user}/${opc_compute_route.mysql_vip_route.name}"
    mysql_vnset = "/Compute-${var.domain}/${var.user}/${opc_compute_vnic_set.mysql_01.name}"
  }
}

variable "search"  { default = "https:" }
variable "replace" { default = "" }
variable "nextSearch" { default = "/"}

data "template_file" "default_profile" {
  template = "${file("templates/default.tpl")}"

  vars {
    opc_user = "/Compute-${var.domain}/${var.user}"
    opc_endpoint = "${replace(replace(var.endpoint, var.search, var.replace), var.nextSearch ,var.replace)}"
  }
}

data "template_file" "pwd" {
  template = "$${pwd}"

  vars {
    pwd = "${var.password}"
  }
}

resource "opc_compute_ip_network" "ip-network-1" {
  name = "Pirvate_IPNetwork"
  description = "MySQL DB Network"
  ip_address_prefix = "192.168.2.0/24"
}

resource "opc_compute_instance" "instance-1" {
	name = "mysql_01"
  hostname = "mysql01"
	label = "mysql_01"
	shape = "oc3"
	image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  networking_info {
    index = 0
    ip_network = "${opc_compute_ip_network.ip-network-1.name}"
    ip_address = "192.168.2.11"
    vnic_sets = ["${opc_compute_vnic_set.mysql_01.name}", "/Compute-${var.domain}/default"]
    name_servers = ["8.8.8.8"]
  }
  ssh_keys = [ "${opc_compute_ssh_key.ssh_key.name}" ]

  provisioner "file" {
    source      = "conf/"
    destination = "/tmp"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.11"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.mysql1_sh.rendered}"
    destination = "/tmp/mysql.sh"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.11"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.default_profile.rendered}"
    destination = "/tmp/default"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.11"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.pwd.rendered}"
    destination = "/tmp/pwd"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.11"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    source      = "scripts/mysql-init.sh"
    destination = "/tmp/mysql-init.sh"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.11"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mysql-init.sh",
      "sudo /tmp/mysql-init.sh 1",
      "rm -fr /tmp/mysql-init.sh",
    ]

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.11"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

}

resource "opc_compute_instance" "instance-2" {
	name = "mysql_02"
  hostname = "mysql02"
	label = "mysql_02"
	shape = "oc3"
	image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  networking_info {
    index = 0
    ip_network = "${opc_compute_ip_network.ip-network-1.name}"
    ip_address = "192.168.2.12"
    vnic_sets = ["${opc_compute_vnic_set.mysql_02.name}", "/Compute-${var.domain}/default"]
    name_servers = ["8.8.8.8"]
  }
  ssh_keys = [ "${opc_compute_ssh_key.ssh_key.name}" ]

  provisioner "file" {
    source      = "conf/"
    destination = "/tmp"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.mysql2_sh.rendered}"
    destination = "/tmp/mysql.sh"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.default_profile.rendered}"
    destination = "/tmp/default"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.default_profile.rendered}"
    destination = "/tmp/default"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    content = "${data.template_file.pwd.rendered}"
    destination = "/tmp/pwd"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    source      = "scripts/mysql-init.sh"
    destination = "/tmp/mysql-init.sh"

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mysql-init.sh",
      "sudo /tmp/mysql-init.sh 2",
      "rm -fr /tmp/mysql-init.sh",
    ]

    connection {
      type = "ssh"
      user = "opc"
      host = "192.168.2.12"
      private_key = "${file(var.ssh_private_key)}"
      bastion_host = "${opc_compute_ip_reservation.reservation1.ip}"
      bastion_private_key = "${file(var.ssh_private_key)}"
    }
  }
}

resource "opc_compute_instance" "instance-3" {
	name = "nat_instance"
  hostname = "nat"
	label = "nat_instance"
	shape = "oc3"
	image_list = "/oracle/public/OL_7.2_UEKR4_x86_64"
  networking_info {
    index = 0
    shared_network = true
    nat = [ "${opc_compute_ip_reservation.reservation1.name}" ]
    name_servers = ["8.8.8.8"]
  }
  networking_info {
    index = 1
    ip_network = "${opc_compute_ip_network.ip-network-1.name}"
    ip_address = "192.168.2.101"
    vnic_sets = ["${opc_compute_vnic_set.nat_set.name}", "/Compute-${var.domain}/default"]
    name_servers = ["8.8.8.8"]
  }
  ssh_keys = [ "${opc_compute_ssh_key.ssh_key.name}" ]

  instance_attributes = <<JSON
  {
    "userdata":{
      "pre-bootstrap": {
        "failonerror": true,
        "script": [
          "sysctl -w net.ipv4.ip_forward=1",
          "systemctl start iptables",
          "iptables -t nat -A POSTROUTING -o eth0 -s 192.168.2.0/24 -j MASQUERADE",
          "iptables -D FORWARD 1",
          "yum install -y mysql"
        ]
      }
    }
  }
  JSON
}

resource "opc_compute_ip_reservation" "reservation1" {
	parent_pool = "/oracle/public/ippool"
	permanent = true
}

output "public_ip" {
  value = "${opc_compute_ip_reservation.reservation1.ip}"
}
