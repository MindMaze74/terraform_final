# Итоговый отчёт по практике

> **ТЗ:** [TASK.md](TASK.md)
> **Архитектура:** [architecture.md](architecture.md)
> **Развёртывание:** [DEPLOYMENT.md](DEPLOYMENT.md)
> **Репозиторий:** [terraform_final](https://github.com/MindMaze74/terraform_final)

**Выполнил:** Старцев Данила Антонович
**Модуль:** «Облачная инфраструктура. Terraform»
**Terraform:** `~> 1.12.0`
**Облако:** Yandex Cloud
**Стек:** Python 3.12 + FastAPI + Uvicorn + MySQL 8 + Docker + GitHub Actions

---

## Краткое резюме

Проект реализует полный цикл развёртывания web-приложения в Yandex Cloud:

1. **Инфраструктура** описана декларативно в Terraform — VPC, Security Group, Managed MySQL, Container Registry, VM.
2. **Docker и Docker Compose** устанавливаются автоматически через `cloud-init`.
3. **Приложение** упаковано в multi-stage Docker-образ и сохранено в Container Registry.
4. **Связь с Managed MySQL** через переменные окружения.
5. **CI/CD** через GitHub Actions — автоматическое создание и удаление инфраструктуры.
6. **Trivy** — сканирование образа на уязвимости.

---

## Соответствие ТЗ → Реализация

| # | Требование ТЗ | Что сделано | Ссылка на код |
|---|---|---|---|
| 1 | VPC + подсети | `module.vpc`: VPC `final` + подсеть `10.0.1.0/24` | [main.tf](../terraform/main.tf) |
| 2 | Security Group (22, 80, 443) | `yandex_vpc_security_group.web` + правило MySQL 3306 | [main.tf](../terraform/main.tf) |
| 3 | Managed MySQL | `yandex_mdb_mysql_cluster.db` (MySQL 8.0, s2.micro) | [main.tf](../terraform/main.tf) |
| 4 | Container Registry | `yandex_container_registry.app` | [main.tf](../terraform/main.tf) |
| 5 | Docker через cloud-init | `cloud-init.yml`: Docker CE + Compose Plugin | [cloud-init.yml](../terraform/cloud-init.yml) |
| 6 | Multi-stage Dockerfile | `app_python/Dockerfile`: builder + runtime | [Dockerfile](../app_python/Dockerfile) |
| 7 | Образ в Container Registry | `cr.yandex/crpet3e9fclqrqdqslgq/app:latest` | [outputs.tf](../terraform/outputs.tf) |
| 8 | Приложение ↔ MySQL | ENV: `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` | [main.py](../app_python/main.py) |
| 9 | LockBox | `yandex_lockbox_secret.db` (опционально) | [lockbox.tf](../terraform/lockbox.tf) |
| 10 | Remote state + locking | S3 backend, `use_lockfile = true` | [providers.tf](../terraform/providers.tf) |
| 11 | Приложение по IP | `http://89.169.154.42/` | [DEPLOYMENT.md](DEPLOYMENT.md) |
| 12 | MD-отчёт | `README.md` + `docs/*.md` | [README.md](../README.md) |

---

## Задание 1 — Инфраструктура

### Ресурсы

| Ресурс | Назначение |
|---|---|
| `module.vpc` | VPC `final` + подсеть `10.0.1.0/24` |
| `yandex_vpc_security_group.web` | SG с правилами 22, 80, 443, 3306 |
| `yandex_mdb_mysql_cluster.db` | Managed MySQL 8.0, s2.micro |
| `yandex_mdb_mysql_database.db` | БД `app_db` |
| `yandex_mdb_mysql_user.user` | Пользователь `app` с ролью ALL |
| `yandex_container_registry.app` | Registry `final-app-registry` |
| `module.vm` | ВМ `final-web-vm` (Ubuntu 22.04) |

### Код

**`terraform/main.tf`** (фрагмент):

```hcl
module "vpc" {
  source   = "./modules/vpc"
  env_name = var.vpc_name
  subnets  = var.vpc_subnets
}

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
    description    = "MySQL from VPC"
    port           = 3306
    protocol       = "TCP"
    v4_cidr_blocks = [var.db_cidr]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
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
```

### Проверка

```bash
terraform plan
# Plan: 9 to add, 0 to change, 0 to destroy.

---

## Задание 2 — Docker через cloud-init

Установка Docker и Docker Compose происходит автоматически при первом запуске ВМ.

**`terraform/cloud-init.yml`** (фрагмент):

```yaml
runcmd:
  # Освобождаем порт 80 (Ubuntu image содержит Apache)
  - systemctl stop apache2 || true
  - systemctl disable apache2 || true

  # Установка Docker
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  # ... установка docker-ce, docker-compose-plugin

  # Авторизация в Container Registry через IAM-токен SA
  - |
    TOKEN=$(curl -s -H Metadata-Flavor:Google \
      "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token" \
      | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    echo "$TOKEN" | docker login --username iam --password-stdin cr.yandex

  # Создание docker-compose.yml и запуск
  - mkdir -p /home/ubuntu/app
  - |
    cat > /home/ubuntu/app/docker-compose.yml <<'COMPOSE'
    version: '3.8'
    services:
      web:
        image: ${app_image}
        ports:
          - "80:5000"
        environment:
          DB_HOST: ${db_host}
          DB_PORT: 3306
          DB_NAME: ${db_name}
          DB_USER: ${db_user}
          DB_PASSWORD: ${db_password}
    COMPOSE
  - cd /home/ubuntu/app && docker compose up -d

---

## Задание 3 — Dockerfile (multi-stage) + Registry

**`app_python/Dockerfile`:**

```dockerfile
FROM python:3.12-slim AS builder
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim AS runtime
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY main.py .
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
EXPOSE 5000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
```

### Сборка и push

```bash
docker build --provenance=false --sbom=false \
  -t cr.yandex/crpet3e9fclqrqdqslgq/app:latest .
docker push cr.yandex/crpet3e9fclqrqdqslgq/app:latest

---

## Задание 4 — Связь с MySQL

Приложение на Python + FastAPI подключается к Managed MySQL через ENV.

**`app_python/main.py`** (фрагмент):

```python
db_host = os.environ.get('DB_HOST', '127.0.0.1')
db_user = os.environ.get('DB_USER', 'app')
db_password = os.environ.get('DB_PASSWORD', 'very_strong')
db_name = os.environ.get('DB_NAME', 'example')

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Приложение запускается...")
    if ensure_table_exists():
        print("Соединение с БД установлено...")
    yield
---

## Задание 5* — LockBox

Пароль от БД хранится в Yandex LockBox и читается через Terraform.

**`terraform/lockbox.tf`:**

```hcl
resource "yandex_lockbox_secret" "db" {
  name = "db-password"
}

resource "yandex_lockbox_secret_version" "db" {
  secret_id = yandex_lockbox_secret.db.id
  entries {
    key        = "password"
    text_value = random_password.db.result
  }
}
```

---

## CI/CD через GitHub Actions

**`.github/workflows/terraform.yml`:**

| Триггер | Действие |
|---|---|
| push в `main` | init → plan → apply |
| `workflow_dispatch` | init → plan → destroy |

**`.github/workflows/security-scan.yml`** — Trivy:

| Триггер | Действие |
|---|---|
| push в `app_python/**` | Сборка образа + сканирование |
| `workflow_dispatch` | Ручной запуск |

### Секреты

| Секрет | Назначение |
|---|---|
| `YC_ACCESS_KEY` | Static access key (backend S3) |
| `YC_SECRET_KEY` | Static secret key (backend S3) |
| `YC_CLOUD_ID` | ID облака |
| `YC_FOLDER_ID` | ID каталога |
| `YC_SSH_PUBLIC_KEY` | Публичный SSH-ключ |
| `YC_SERVICE_ACCOUNT_KEY_JSON` | base64 от JSON-ключа SA |

---

## Документация Terraform

Автоматически сгенерированная документация доступна в `terraform/TERRAFORM_DOCS.md`.

Для пересборки:

```bash
cd terraform
terraform-docs markdown table --output-file TERRAFORM_DOCS.md .
cd modules/vpc && terraform-docs markdown table --output-file README.md .
cd ../vm && terraform-docs markdown table --output-file README.md .
```

---

## Результат развёртывания

Приложение успешно развёрнуто в Yandex Cloud:

- **Внешний IP:** `89.169.154.42`
- **URL:** `http://89.169.154.42/`
- **Ответ приложения:** `TIME: 2026-09-17 17:17:27, IP: None`

### Компоненты инфраструктуры

| Компонент | Статус |
|---|---|
| VPC `final` + подсеть `10.0.1.0/24` | Готово |
| Security Group `final-web-sg` (22, 80, 443, 3306) | Готово |
| Managed MySQL `final-mysql` (Running) | Готово |
| Container Registry `final-app-registry` + образ `app:latest` | Готово |
| VM `final-web-vm` + Docker + контейнер | Готово |
| Cloud-init: Docker + pull из Registry через IAM-токен SA | Готово |

---

## Итоги

| Требование | Статус |
|---|---|
| Инфраструктура в Yandex Cloud | Выполнено |
| Приложение доступно по IP | Выполнено |
| Dockerfile с multi-stage | Выполнено |
| Образ в Container Registry | Выполнено |
| VM управляется через Terraform | Выполнено |
| Infra без хардкода | Выполнено |
| Remote state + locking | Выполнено |
| Docker + Compose через cloud-init | Выполнено |
| LockBox | Выполнено |
| CI/CD через GitHub Actions | Выполнено |
| Trivy security scan | Выполнено |
| terraform-docs | Выполнено |
| MD-отчёт | Выполнено |
| Код в Git | Выполнено |

---

## Использованные инструменты

- Terraform `~> 1.12.0`
- Yandex Cloud: Compute, VPC, Managed MySQL, Container Registry, LockBox, Object Storage
- Docker + Docker Compose
- Python 3.12 + FastAPI + Uvicorn + mysql-connector-python
- GitHub Actions — CI/CD
- Trivy — сканирование уязвимостей
- terraform-docs — документация
- Mermaid — диаграммы

---

## Ссылки

- [Репозиторий](https://github.com/MindMaze74/terraform_final)
- [ТЗ](TASK.md)
- [Архитектура](architecture.md)
- [Развёртывание](DEPLOYMENT.md)
- [Terraform-документация](../terraform/TERRAFORM_DOCS.md)
