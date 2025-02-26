terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  auth_url    = "http://10.128.0.8/identity/v3"
  user_name   = "admin"
  password    = "nav+sanjeev"
  tenant_name = "admin"
  region      = "RegionOne"
}

resource "openstack_compute_instance_v2" "databag_instance" {
  name            = "databag-server"
  image_name      = "Ubuntu 22.04" 
  flavor_name     = "m1.small"      
  key_pair        = "databag-keypair"
  security_groups = ["default"]

  network {
    name = "private"
  }
}

resource "openstack_networking_floatingip_v2" "databag_ip" {
  pool = "public"
}

output "vm_ip" {
  value = openstack_compute_instance_v2.databag_vm.access_ip_v4
}
