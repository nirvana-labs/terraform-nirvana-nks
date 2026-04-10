<!-- BEGIN_TF_DOCS -->
# Nirvana NKS Terraform module

Terraform module which creates [NKS](https://nirvanalabs.io/) (Nirvana Kubernetes Service) cluster resources.

## Authentication

The Nirvana provider authenticates via the `NIRVANA_LABS_API_KEY` environment variable. Copy the example env file and fill in your key:

```bash
cp .env.example .env
# edit .env with your API key
set -a; source .env; set +a
```

## Usage

```hcl
module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 1.0"

  cluster_name = "basic-demo"
  project_id   = var.project_id
  region       = "us-sva-2"

  node_pools = {
    default = {
      node_count    = 2
      instance_type = "n1-standard-8"
    }
  }
}
```

The module creates a managed NKS cluster with a VPC, worker node pools, and firewall rules for Kubernetes API access, HTTP/HTTPS ingress, and RKE2/Cilium intra-cluster communication. The control plane is fully managed by the NKS platform.

> **Note:** After `terraform apply` completes, the control plane needs ~5 minutes before it is reachable and the kubeconfig can be fetched. Worker nodes are typically ready ~8 minutes after apply.

## Existing VPC

By default the module creates a new VPC. To use an existing VPC, set `create_vpc = false` and pass `vpc_id`:

```hcl
module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 1.0"

  cluster_name = "existing-vpc-demo"
  project_id   = var.project_id
  create_vpc   = false
  vpc_id       = nirvana_networking_vpc.this.id

  node_pools = {
    default = {
      node_count    = 2
      instance_type = "n1-standard-8"
    }
  }
}
```

> **Note:** Only one NKS cluster per VPC is supported.

## Multiple node pools

Define heterogeneous worker pools by adding entries to the `node_pools` map:

```hcl
module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 1.0"

  cluster_name = "multi-pool-demo"
  project_id   = var.project_id

  node_pools = {
    general = {
      node_count    = 3
      instance_type = "n1-standard-8"
    }
    compute = {
      node_count       = 2
      instance_type    = "n1-standard-16"
      boot_volume_size = 200
    }
  }

  management_cidrs = ["10.0.0.0/8"]
  ingress_cidrs    = ["0.0.0.0/0"]
}
```

Pools can be added, removed, or resized independently — the module uses `for_each` so changes to one pool do not affect others.

## Adding a node pool to an existing cluster

Use the `node-pool` submodule to manage pools in a separate Terraform configuration:

```hcl
module "gpu_pool" {
  source = "nirvana-labs/nks/nirvana//modules/node-pool"

  cluster_id    = module.nks.cluster_id
  name          = "gpu"
  node_count    = 2
  instance_type = "n1-standard-16"
}
```

## Firewall rules

The module creates default firewall rules for:

| Rule | Protocol | Ports | Source |
|------|----------|-------|--------|
| K8s API | TCP | 6443 | `management_cidrs` |
| HTTP/HTTPS ingress | TCP | 80, 443 | `ingress_cidrs` |
| RKE2 intra-cluster | TCP | 2379-2381, 4240, 4244, 6443, 9345, 10250, 30000-32767 | VPC subnet |
| Cilium overlay | UDP | 8472, 51871 | VPC subnet |

Management and ingress rules target the K8s API VIP and Cilium ingress VIP respectively (not the whole subnet). Set `create_firewall_rules = false` to manage firewall rules externally.

See the [RKE2 network requirements](https://docs.rke2.io/install/requirements?cni-rules=Cilium#inbound-network-rules) for details on intra-cluster ports.

## Examples

- [Basic](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/basic) — Minimal cluster with a single worker pool
- [Multiple pools](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/multi-pool) — Heterogeneous worker pools with restricted management CIDRs
- [Existing VPC](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/existing-vpc) — Cluster in a pre-existing VPC

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_nirvana"></a> [nirvana](#requirement\_nirvana) | >= 1.32 |
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_nirvana"></a> [nirvana](#provider\_nirvana) | >= 1.32 |
## Modules

No modules.
## Resources

| Name | Type |
| ---- | ---- |
| [nirvana_networking_firewall_rule.api](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_firewall_rule) | resource |
| [nirvana_networking_firewall_rule.ingress](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_firewall_rule) | resource |
| [nirvana_networking_firewall_rule.rke2_tcp](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_firewall_rule) | resource |
| [nirvana_networking_firewall_rule.rke2_udp](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_firewall_rule) | resource |
| [nirvana_networking_vpc.this](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_vpc) | resource |
| [nirvana_nks_cluster.this](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/nks_cluster) | resource |
| [nirvana_nks_node_pool.workers](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/nks_node_pool) | resource |
| [nirvana_networking_vpc.existing](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/data-sources/networking_vpc) | data source |
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the NKS cluster. | `string` | `"my-cluster"` | no |
| <a name="input_create_firewall_rules"></a> [create\_firewall\_rules](#input\_create\_firewall\_rules) | Whether to create the default RKE2/Cilium intra-cluster and access firewall rules. | `bool` | `true` | no |
| <a name="input_ingress_cidrs"></a> [ingress\_cidrs](#input\_ingress\_cidrs) | CIDRs allowed to access the shared Cilium ingress (HTTP 80, HTTPS 443). | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs) | CIDRs allowed to access the Kubernetes API (6443). | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of worker node pool definitions. Keys are pool names. | <pre>map(object({<br/>    node_count       = number<br/>    instance_type    = string<br/>    boot_volume_size = optional(number, 100)<br/>    boot_volume_type = optional(string, "abs")<br/>    tags             = optional(list(string), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Nirvana Labs project ID. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Nirvana Labs region to deploy in. | `string` | `"us-sva-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to attach to all resources. | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of an existing VPC. If null, a new VPC is created. Only one NKS cluster per VPC is supported. | `string` | `null` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name for the created VPC and subnet. Defaults to cluster\_name. Ignored when vpc\_id is set. | `string` | `null` | no |
## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the NKS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the NKS cluster. |
| <a name="output_cluster_private_ip"></a> [cluster\_private\_ip](#output\_cluster\_private\_ip) | Private IP (K8s API VIP) of the cluster. |
| <a name="output_cluster_public_ip"></a> [cluster\_public\_ip](#output\_cluster\_public\_ip) | Public IP of the cluster. |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the cluster. |
| <a name="output_ingress_vip"></a> [ingress\_vip](#output\_ingress\_vip) | Private IP of the shared Cilium ingress (second-to-last IP in the subnet). |
| <a name="output_node_pool_ids"></a> [node\_pool\_ids](#output\_node\_pool\_ids) | Map of worker node pool names to their IDs. |
| <a name="output_subnet_cidr"></a> [subnet\_cidr](#output\_subnet\_cidr) | CIDR of the VPC subnet. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC (created or existing). |

## Authors

Module is maintained by [Nirvana Labs](https://nirvanalabs.io/).

## License

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.
<!-- END_TF_DOCS -->