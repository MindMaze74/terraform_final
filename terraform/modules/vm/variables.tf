variable "env_name" {
  type = string
}

variable "zone" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "labels" {
  type = map(string)
}

variable "cloud_init" {
  type = string
}

variable "image_id" {
  type    = string
  default = "fd827b91d99psvq5fjit"  # Ubuntu 22.04 LTS
}

variable "disk_size" {
  type    = number
  default = 15
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}