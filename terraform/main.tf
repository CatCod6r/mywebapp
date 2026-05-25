terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
    }
  }
}

resource "virtualbox_server" "worker" {
  name      = "lab4-worker"
  image     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.disk1.vmdk"
  cpus      = 1
  memory    = "1024 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }

  network_adapter {
    type           = "nat"
    nat_whitelist  = ["80:80"]
  }
}

resource "virtualbox_server" "db" {
  name      = "lab4-db"
  image     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.disk1.vmdk"
  cpus      = 1
  memory    = "1024 mib"

  network_adapter {
    type           = "hostonly"
    host_interface = "vboxnet0"
  }
}
