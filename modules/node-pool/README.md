<!-- BEGIN_TF_DOCS -->
# node-pool

Standalone submodule for adding a worker node pool to an existing NKS cluster. Useful when the cluster is managed in a separate Terraform configuration (e.g. platform team manages the cluster, app teams manage their own pools).

## Usage

```hcl
module "gpu_pool" {
  source = "nirvana-labs/nks/nirvana//modules/node-pool"

  cluster_id    = "cluster-id"
  name          = "gpu"
  node_count    = 2
  instance_type = "n1-standard-16"
}
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_nirvana"></a> [nirvana](#requirement\_nirvana) | >= 1.41 |
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_nirvana"></a> [nirvana](#provider\_nirvana) | >= 1.41 |
## Resources

| Name | Type |
| ---- | ---- |
| [nirvana_nks_node_pool.this](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/nks_node_pool) | resource |
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_boot_volume_size"></a> [boot\_volume\_size](#input\_boot\_volume\_size) | Boot volume size in GB (64-512). | `number` | `100` | no |
| <a name="input_boot_volume_type"></a> [boot\_volume\_type](#input\_boot\_volume\_type) | Boot volume type: nvme or abs. | `string` | `"abs"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID of the NKS cluster to add the node pool to. | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type for the nodes (e.g. n1-standard-8). | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the node pool. | `string` | n/a | yes |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of nodes in the pool (1-100). | `number` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to attach to the node pool. | `list(string)` | `[]` | no |
## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | ID of the node pool. |
| <a name="output_name"></a> [name](#output\_name) | Name of the node pool. |
| <a name="output_status"></a> [status](#output\_status) | Status of the node pool. |
<!-- END_TF_DOCS -->