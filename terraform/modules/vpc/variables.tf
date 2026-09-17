variable "env_name" {
  type        = string
  description = "Название окружения"
}

variable "subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  description = "Список подсетей для создания"
}