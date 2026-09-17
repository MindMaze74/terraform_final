###cloud vars

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "vpc_name" {
  type        = string
  default     = "final"
  description = "VPC network & subnet name"
}

variable "service_account_key_file" {
  type        = string
  description = ""
  default     = ""
}

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH-ключ для ВМ. Пусто при локальной работе"
  default     = ""
}
variable "service_account_id" {
  type        = string
  description = "ID сервисного аккаунта для ВМ (pull из Container Registry)"
}

variable "vpc_subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  default = [
    { zone = "ru-central1-a", cidr = "10.0.1.0/24" }
  ]
  description = "Список подсетей для создания"
}

variable "db_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Зона доступности для MySQL-хоста и ВМ"
}

variable "db_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR подсети (для SG и выбора subnet_id)"
}
