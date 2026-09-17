# =====================================================
# VPC + подсеть
# =====================================================
module "vpc" {
  source   = "./modules/vpc"
  env_name = var.vpc_name
  subnets  = var.vpc_subnets
}

# =====================================================
# Security Group
# =====================================================
resource "yandex_vpc_security_group" "web" {
  name       = "final-web-sg"
  network_id = module.vpc.network_id

  ingress {
    description    = "SSH"
    port           = 22
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "HTTP"
    port           = 80
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "HTTPS"
    port           = 443
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "MySQL from VPC"
    port           = 3306
    protocol       = "TCP"
    v4_cidr_blocks = [var.db_cidr]
  }
  egress {
    description    = "Any outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# =====================================================
# MySQL Managed Cluster
# =====================================================
resource "random_password" "db" {
  length  = 16
  special = false
}

resource "yandex_mdb_mysql_cluster" "db" {
  name               = "final-mysql"
  environment        = "PRESTABLE"
  network_id         = module.vpc.network_id
  version            = "8.0"
  security_group_ids = [yandex_vpc_security_group.web.id]

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 10
  }

  host {
    zone      = var.db_zone
    subnet_id = module.vpc.subnet_ids["${var.db_zone}-${var.db_cidr}"]
  }
}

resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.db.id
  name       = "app_db"
}

resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.db.id
  name       = "app"
  password   = random_password.db.result

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = ["ALL"]
  }
}

# =====================================================
# Container Registry
# =====================================================
resource "yandex_container_registry" "app" {
  name      = "final-app-registry"
  folder_id = var.folder_id
}

# =====================================================
# Virtual Machine
# =====================================================
module "vm" {
  source             = "./modules/vm"
  env_name           = "final-web"
  zone               = var.db_zone
  subnet_id          = module.vpc.subnet_ids["${var.db_zone}-${var.db_cidr}"]
  ssh_public_key     = var.ssh_public_key
  security_group_ids = [yandex_vpc_security_group.web.id]
  service_account_id = var.service_account_id

  labels = {
    project = "final"
  }

  cloud_init = templatefile("${path.module}/cloud-init.yml", {
    ssh_public_key = var.ssh_public_key
    app_image      = "cr.yandex/${yandex_container_registry.app.id}/app:latest"
    db_host        = yandex_mdb_mysql_cluster.db.host[0].fqdn
    db_name        = yandex_mdb_mysql_database.db.name
    db_user        = yandex_mdb_mysql_user.user.name
    db_password    = random_password.db.result
  })
}