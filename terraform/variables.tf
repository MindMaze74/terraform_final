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