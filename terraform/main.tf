resource "time_sleep" "wait_10_seconds" {
  create_duration = "10s"
}

resource "yandex_storage_bucket" "test_bucket" {
  bucket = var.bucket_name
  acl = "public-read"
}

resource "yandex_storage_object" "cute_picture" {
  depends_on = [time_sleep.wait_10_seconds]
  bucket = var.bucket_name
  key    = var.file_name
  source = var.file_name
  acl    = "public-read"
}


resource "yandex_compute_instance_group" "group_vms" {
  name                = "ig1"
  folder_id           = var.folder_id
  service_account_id  = var.service_account_id
  instance_template {
    platform_id = var.platform-id
    resources {
      memory = var.resource-groupe-vms.memory
      cores  = var.resource-groupe-vms.cores
      core_fraction = var.resource-groupe-vms.core_fraction
    }
    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.lamp_iso_for_ig
        size     = 3
      }
    }
    network_interface {
      network_id = yandex_vpc_network.vpc_network.id
      subnet_ids = ["${yandex_vpc_subnet.public_subnet.id}"]
    }

    metadata = {
      ssh-keys = "ubuntu:${var.vm-ssh-metadata}"
      user-data = <<EOF
#cloud-config
datasource:
  Ec2:
    strict_id: false
ssh_pwauth: no
users:
- name: ubuntu
  sudo: 'ALL=(ALL) NOPASSWD:ALL'
  shell: /bin/bash
  ssh_authorized_keys:
  - ${var.vm-ssh-metadata}
write_files:
  - path: "/usr/local/etc/startup.sh"
    permissions: "755"
    content: |
      #!/bin/bash
      sudo chown -R ubuntu:www-data /var/www/html
      echo "https://storage.yandexcloud.net/${var.bucket_name}/${var.file_name}" > /var/www/html/index.html
    defer: true
runcmd:
  - ["/usr/local/etc/startup.sh"]
EOF
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["${var.default_zone}"]
  }
  
  deploy_policy {
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  health_check {
    http_options {
      path = "/"
      port = 80
    }
    interval = 10
    timeout  = 5
    unhealthy_threshold = 5
    healthy_threshold   = 3
  }

    load_balancer {
    target_group_name        = "target-group"
  }
}

resource "yandex_lb_network_load_balancer" "network_loader" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.group_vms.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}