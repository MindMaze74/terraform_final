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
cloud_id                 = "b1gervu69........"
folder_id                = "b1g4blc2......."
service_account_key_file = "/home/user/authorized_key.json"
service_account_id       = "ajevcaj......"
ssh_public_key           = "ssh-rsa AAAA..."
```

**Важно:** `service_account_id` — это ID сервисного аккаунта (вида `aje...`), у которого есть роли:

- `container-registry.images.puller` — для pull образа из Registry на ВМ
- `storage.editor` — для доступа к backend S3

Узнать ID:

```bash
yc iam service-account get --name terraform-dz5
```

## 4. Аутентификация

Static access keys для backend S3 — в `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YCAJE...
aws_secret_access_key = YCM...
```

Файл создаётся в домашней папке, не попадает в git.

### 4.1. Секреты GitHub Actions (для CI/CD)

При использовании workflow `.github/workflows/terraform.yml` добавьте в
**Settings → Secrets and variables → Actions** следующие секреты:

| Секрет | Назначение |
|---|---|
| `YC_ACCESS_KEY` | Static access key (backend S3) |
| `YC_SECRET_KEY` | Static secret key (backend S3) |
| `YC_CLOUD_ID` | ID облака |
| `YC_FOLDER_ID` | ID каталога |
| `YC_SERVICE_ACCOUNT_ID` | ID SA для ВМ (pull из Container Registry) |
| `YC_SERVICE_ACCOUNT_KEY_JSON` | base64 от JSON-ключа SA |
| `YC_SSH_PUBLIC_KEY` | Публичный SSH-ключ |

Как получить base64 от JSON-ключа:

```bash
cat ~/authorized_key.json | base64 -w0
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

**Перед `destroy` удалите образы из Container Registry** — Terraform не сможет удалить Registry, пока там есть образы.

```bash
REGISTRY_ID=$(cd terraform && terraform output -raw registry_id)

# Удалить все образы
for id in $(yc container image list --registry-id $REGISTRY_ID --format json | jq -r '.[].id'); do
  yc container image delete --id $id
done
```

Затем:

**Через GitHub Actions:**

Actions → Terraform CI/CD → Run workflow → main.

**Или локально:**

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
| Приложение виснет на старте | Проверьте SG-правило для 3306 (MySQL из VPC) |
| `var.service_account_id` not set (в CI) | Добавьте секрет `YC_SERVICE_ACCOUNT_ID` в GitHub Actions |
| Registry is not empty при destroy | Удалите образы: `yc container image delete --id <ID>` |