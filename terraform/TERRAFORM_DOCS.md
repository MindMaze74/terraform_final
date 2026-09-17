<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.12.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | ~> 0.226.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.226.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vm"></a> [vm](#module\_vm) | ./modules/vm | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [random_password.db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [yandex_container_registry.app](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/container_registry) | resource |
| [yandex_mdb_mysql_cluster.db](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_cluster) | resource |
| [yandex_mdb_mysql_database.db](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_database) | resource |
| [yandex_mdb_mysql_user.user](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/mdb_mysql_user) | resource |
| [yandex_vpc_security_group.web](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cloud_id"></a> [cloud\_id](#input\_cloud\_id) | https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id | `string` | n/a | yes |
| <a name="input_default_zone"></a> [default\_zone](#input\_default\_zone) | https://cloud.yandex.ru/docs/overview/concepts/geo-scope | `string` | `"ru-central1-a"` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id | `string` | n/a | yes |
| <a name="input_service_account_key_file"></a> [service\_account\_key\_file](#input\_service\_account\_key\_file) | n/a | `string` | `""` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Публичный SSH-ключ для ВМ. Пусто при локальной работе | `string` | `""` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPC network & subnet name | `string` | `"develop"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_password"></a> [db\_password](#output\_db\_password) | Пароль от БД (sensitive) |
| <a name="output_mysql_fqdn"></a> [mysql\_fqdn](#output\_mysql\_fqdn) | FQDN MySQL-кластера |
| <a name="output_registry_id"></a> [registry\_id](#output\_registry\_id) | ID Container Registry |
| <a name="output_registry_url"></a> [registry\_url](#output\_registry\_url) | URL для docker push |
| <a name="output_vm_external_ip"></a> [vm\_external\_ip](#output\_vm\_external\_ip) | Внешний IP веб-сервера |
| <a name="output_vm_internal_ip"></a> [vm\_internal\_ip](#output\_vm\_internal\_ip) | Внутренний IP веб-сервера |
<!-- END_TF_DOCS -->