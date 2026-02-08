data "yandex_compute_image" "ubuntu1" {
  family = var.vm_yandex_compute_image_family
}

resource "yandex_compute_instance" "nat-instance" {
  name        = "nat"
  platform_id = var.platform-id
  zone        = var.default_zone

  resources {
    cores  = var.resources-for-nat-instance.cores
    memory = var.resources-for-nat-instance.memory
    core_fraction = var.resources-for-nat-instance.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1" 
    }
  }
  scheduling_policy {
    preemptible = var.scheduling-policy
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    ip_address = var.ip-nat-instance
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.vm-ssh-metadata}"
  }
}