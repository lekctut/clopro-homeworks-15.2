output "file_http_url" {
  value = "https://storage.yandexcloud.net/${var.bucket_name}/${var.file_name}"
}

output "internal_ip_address_nat_vm" {
  value = yandex_compute_instance.nat-instance.network_interface.0.ip_address
}

output "external_ip_address_nat_vm" {
  value = yandex_compute_instance.nat-instance.network_interface.0.nat_ip_address
}