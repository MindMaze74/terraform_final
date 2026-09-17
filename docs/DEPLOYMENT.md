# Развёртывание

## Предварительные требования

- Terraform `~> 1.12.0`
- Yandex Cloud CLI (`yc`)
- Docker
- SSH-ключ

## 1. Клонирование репозитория

```bash
git clone https://github.com/MindMaze74/terraform_final.git
cd terraform_final
```

## 2. Настройка backend

В `terraform/providers.tf` укажите ваш S3 bucket:

```hcl
backend "s3" {
  bucket       = "your-bucket-name"
  key          = "terraform_final/terraform.tfstate"
  region       = "ru-central1"
  use_lockfile = true
  endpoints    = { s3 = "https://storage.yandexcloud.net" }

  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_s3_checksum            = true
}
```

## 3. Переменные

Создайте `terraform/personal.auto.tfvars` (файл в `.gitignore`):

```hcl
cloud_id                 = "b1gervu69v9ig93k4v83"
folder_id                = "b1g4blc2guo29mqbh6bp"
service_account_key_file = "/home/user/authorized_key.json"
service_account_id       = "ajevcajoi6sqvd59cbs9"
ssh_public_key           = "ssh-rsa AAAA..."
```

## 4. Аутентификация

Static access keys для backend S3 — в `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YCAJE...
aws_secret_access_key = YCM...
```

## 5. Применение инфраструктуры

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

Создаются:

- VPC `final` + подсеть `10.0.1.0/24`
- Security Group `final-web-sg` (22, 80, 443, 3306)
- Managed MySQL `final-mysql` (s2.micro, 8.0)
- Container Registry `final-app-registry`
- VM `final-web-vm` (Ubuntu 22.04, Docker)

## 6. Сборка и push образа

```bash
cd app_python
REGISTRY_ID=$(cd ../terraform && terraform output -raw registry_id)
yc container registry configure-docker

# Сборка без attestation (совместимость с Yandex Registry)
docker build --provenance=false --sbom=false \
  -t cr.yandex/$REGISTRY_ID/app:latest .

docker push cr.yandex/$REGISTRY_ID/app:latest
```

## 7. Проверка приложения

```bash
cd ../terraform
IP=$(terraform output -raw vm_external_ip)
echo "URL: http://$IP/"

curl http://$IP/
curl http://$IP/requests
```

Ожидаемый результат:

- `/` → `TIME: ..., IP: None`
- `/requests` → JSON с записями

## 8. Удаление ресурсов

Через GitHub Actions:

**Actions → Terraform CI/CD → Run workflow → main.**

Или локально:

```bash
cd terraform
terraform destroy -auto-approve
```

## Возможные проблемы

| Проблема | Решение |
|---|---|
| No valid credential sources found | Проверьте `~/.aws/credentials` для backend |
| Permission denied для SA | Проверьте роли SA (`storage.editor`, `container-registry.images.puller`) |
| unauthorized при pull | Привяжите SA к ВМ (`service_account_id` в `main.tf`) |
| Apache занял порт 80 | Cloud-init делает `systemctl stop apache2` |
| Приложение виснет на старте | Проверьте SG-правило для 3306 |