# Архитектура

## Компоненты

| Компонент | Описание |
|---|---|
| VPC `final` | Сеть `10.0.1.0/24` в зоне `ru-central1-a` |
| Security Group | Разрешает SSH (22), HTTP (80), HTTPS (443), MySQL (3306) |
| Managed MySQL | Кластер MySQL 8.0, `s2.micro`, 10 ГБ SSD |
| Container Registry | Хранит Docker-образ `app:latest` |
| VM | Ubuntu 22.04, Docker, Docker Compose, FastAPI-приложение |
| LockBox | Пароль от БД (опционально) |

## Поток данных

1. Пользователь открывает `http://<vm_ip>/`.
2. Uvicorn (FastAPI) принимает запрос на порту 5000 (снаружи — 80).
3. Приложение подключается к MySQL по FQDN из переменных окружения.
4. Выполняет `INSERT INTO requests` и возвращает время запроса.
5. Пользователь видит `TIME: ..., IP: None`.

## Схема

```mermaid
flowchart TB
    U["User"] -->|HTTP :80| VM

    subgraph YC["Yandex Cloud"]
        VM["VM: final-web-vm<br/>Docker + FastAPI"]
        MySQL["Managed MySQL<br/>app_db"]
        Reg["Container Registry"]
        LB["LockBox"]
    end

    subgraph CI["CI/CD"]
        GH["GitHub Actions"]
        S3["S3 State"]
    end

    GH -->|apply/destroy| YC
    GH <-->|state| S3
    VM -->|:3306| MySQL
    VM -.->|pull image| Reg
    VM -.->|read secret| LB
```

## CI/CD

```mermaid
sequenceDiagram
    participant Dev as Разработчик
    participant GH as GitHub
    participant Actions as GitHub Actions
    participant TF as Terraform
    participant YC as Yandex Cloud

    Dev->>GH: git push origin main
    GH->>Actions: Trigger workflow
    Actions->>Actions: Checkout + Setup Terraform
    Actions->>TF: terraform init
    TF->>TF: Чтение state из S3
    Actions->>TF: terraform plan
    Actions->>TF: terraform apply
    TF->>YC: Создание ресурсов
    YC-->>TF: Готово
    Actions-->>Dev: Успех

    Note over Dev,YC: При ручном запуске — destroy
    Dev->>Actions: Run workflow (manual)
    Actions->>TF: terraform destroy
    TF->>YC: Удаление ресурсов
    Actions-->>Dev: Удалено
```

## Сетевые порты

| Порт | Назначение | Источник |
|---|---|---|
| 22 | SSH | 0.0.0.0/0 |
| 80 | HTTP (FastAPI) | 0.0.0.0/0 |
| 443 | HTTPS | 0.0.0.0/0 |
| 3306 | MySQL | 10.0.1.0/24 (только VPC) |