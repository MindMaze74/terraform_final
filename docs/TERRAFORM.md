# Документация Terraform

Автоматически сгенерированная документация доступна в [terraform/TERRAFORM_DOCS.md](../terraform/TERRAFORM_DOCS.md).

Для пересборки:

```bash
cd terraform
terraform-docs markdown table --output-file TERRAFORM_DOCS.md .
cd modules/vpc && terraform-docs markdown table --output-file README.md .
cd ../vm && terraform-docs markdown table --output-file README.md .