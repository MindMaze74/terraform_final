output "vm_external_ip" {
  value       = module.vm.external_ip
  description = "Внешний IP веб-сервера"
}

output "vm_internal_ip" {
  value       = module.vm.internal_ip
  description = "Внутренний IP веб-сервера"
}

output "mysql_fqdn" {
  value       = yandex_mdb_mysql_cluster.db.host[0].fqdn
  description = "FQDN MySQL-кластера"
}

output "registry_id" {
  value       = yandex_container_registry.app.id
  description = "ID Container Registry"
}

output "registry_url" {
  value       = "cr.yandex/${yandex_container_registry.app.id}"
  description = "URL для docker push"
}

output "db_password" {
  value       = random_password.db.result
  sensitive   = true
  description = "Пароль от БД (sensitive)"
}