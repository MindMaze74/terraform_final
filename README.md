# Итоговый проект модуля «Облачная инфраструктура. Terraform»

Автоматическое развёртывание web-приложения в Yandex Cloud с использованием Terraform, Docker и GitHub Actions.

**Стек:** Terraform ~> 1.12.0, Yandex Cloud, Docker, Node.js 20, MySQL 8, GitHub Actions.

## Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/MindMaze74/terraform_final.git
cd terraform_final

# 2. Создать personal.auto.tfvars с вашими данными
cat > terraform/personal.auto.tfvars <<EOF
cloud_id                 = "b1gervu69v9ig93k4v83"
folder_id                = "b1g4blc2guo29mqbh6bp"
service_account_key_file = "/home/user/authorized_key.json"
ssh_public_key           = "ssh-rsa AAAA..."
EOF

# 3. Применить инфраструктуру
cd terraform
export AWS_ACCESS_KEY_ID="YCAJE..."
export AWS_SECRET_ACCESS_KEY="YCM..."
terraform init
terraform apply -auto-approve

# 4. Собрать и запушить Docker-образ
cd ../app
REGISTRY_ID=$(cd ../terraform && terraform output -raw registry_id)
yc container registry configure-docker
docker build -t cr.yandex/$REGISTRY_ID/app:latest .
docker push cr.yandex/$REGISTRY_ID/app:latest

# 5. Открыть приложение
cd ../terraform
echo "http://$(terraform output -raw vm_external_ip)/"

# 6. Удалить ресурсы
terraform destroy -auto-approve
```

# Создаваемые ресурсы

## Инфраструктура проекта

### Ресурсы

| Ресурс | Назначение | Статус |
|---|---|---|
| VPC final + подсеть `10.0.1.0/24` | Сеть | Готово |
| Security Group `final-web-sg` | Порты 22, 80, 443 | Готово |
| Managed MySQL `final-mysql` (s2.micro) | База данных | Готово |
| Container Registry `final-app-registry` | Хранение образа | Готово |
| VM `final-web-vm` (Ubuntu 22.04) | Docker + приложение | Готово |
| LockBox `db-password` (опционально) | Секреты | Готово |

### Статус артефактов

| Артефакт | Платформа | Статус |
|---|---|---|
| Docker image | Yandex Container Registry | Собрано и опубликовано |
| Terraform state | S3 (`terraform-dz5-state-.../terraform_final/`) | Готово: Remote + lock |
| CI/CD | GitHub Actions | Готово: Apply + Destroy |

## Документация

- [docs/architecture.md](docs/architecture.md) — схема архитектуры (Mermaid)
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — пошаговое развёртывание
- [docs/REPORT.md](docs/REPORT.md) — итоговый отчёт по практике
- [docs/TERRAFORM_DOCS](docs/TERRAFORM_DOCS.md) — автогенерация terraform-docs


## Скриншоты
