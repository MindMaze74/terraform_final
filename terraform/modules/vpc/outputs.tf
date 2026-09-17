output "network_id" {
  value = yandex_vpc_network.test.id
}

output "subnet_ids" {
  value = { for k, v in yandex_vpc_subnet.test : k => v.id }
}

output "subnet_zones" {
  value = [for s in yandex_vpc_subnet.test : s.zone]
}