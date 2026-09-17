# Итоговый проект модуля «Облачная инфраструктура. Terraform»

Автоматическое развёртывание web-приложения в Yandex Cloud с использованием Terraform, Docker и GitHub Actions.

**Стек:** Terraform ~> 1.12.0, Yandex Cloud, Docker, Python 3.12, FastAPI, Uvicorn, MySQL 8, GitHub Actions.

## Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/MindMaze74/terraform_final.git
cd terraform_final

# 2. Создать personal.auto.tfvars с вашими данными
cat > terraform/personal.auto.tfvars <<EOF
cloud_id                 = "..."
folder_id                = "..."
service_account_key_file = "/home/user/authorized_key.json"
service_account_id       = "..."
ssh_public_key           = "ssh-rsa AAAA..."
EOF

# 3. Применить инфраструктуру
cd terraform
terraform init
terraform apply -auto-approve

# 4. Собрать и запушить образ
cd ../app_python
REGISTRY_ID=$(cd ../terraform && terraform output -raw registry_id)
yc container registry configure-docker
docker build --provenance=false --sbom=false -t cr.yandex/$REGISTRY_ID/app:latest .
docker push cr.yandex/$REGISTRY_ID/app:latest

# 5. Проверить приложение
IP=$(cd ../terraform && terraform output -raw vm_external_ip)
curl http://$IP/
```

## Документация

- [docs/TASK.md](docs/TASK.md) — техническое задание
- [docs/architecture.md](docs/architecture.md) — архитектура и схема пайплайна
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — развёртывание
- [docs/REPORT.md](docs/REPORT.md) — итоговый отчёт

## Структура

```
.
├── app_python/               # FastAPI-приложение
│   ├── Dockerfile            # multi-stage сборка
│   ├── main.py
│   └── requirements.txt
├── docs/                     # документация
│   ├── TASK.md
│   ├── architecture.md
│   ├── DEPLOYMENT.md
│   └── REPORT.md
├── terraform/                # инфраструктура как код
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── lockbox.tf
│   ├── cloud-init.yml
│   └── modules/
│       ├── vpc/
│       └── vm/
└── .github/workflows/        # CI/CD
    ├── terraform.yml
    └── security-scan.yml
```

## Скриншоты

Полный набор скриншотов — в папке [`img/`](img/).

Ключевые:

- [Приложение в облаке](img/5.png) — ответ `TIME: ..., IP: None`
- [Записи в БД](img/6.png) — `/requests`
- [VPC](img/7.png), [Подсеть](img/8.png), [SG](img/9.png), [MySQL](img/10.png), [Registry](img/12.png), [VM](img/13.png)