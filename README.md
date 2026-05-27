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
  version = "~> 0.2.0"

  cluster_name       = "basic-demo"
  kubernetes_version = "v1.34.4"
  project_id         = var.project_id
  region             = "us-sva-2"

  node_pools = {
    default = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
    }
  }
}
```

> **Tip:** Pre-1.0 minor releases may include breaking changes. The `~> 0.2.0` constraint pins to patch-level updates within `0.2.x`. Bump the constraint explicitly when adopting a new minor version.

> **Note:** Examples use small instance types and `node_count = 1` so they fit within trial-account resource quotas. NKS autoscaling is on by default and will scale pools up as workloads demand capacity. Use larger `instance_type`s and higher initial `node_count`s for production sizing.

The module creates a managed NKS cluster with a VPC, worker node pools, and firewall rules for Kubernetes API access and HTTP/HTTPS ingress. The control plane is fully managed by the NKS platform.

> **Note:** `kubernetes_version` is required. Look up available versions via the [`nirvana_nks_cluster_kubernetes_versions`](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/data-sources/nks_cluster_kubernetes_versions) data source. Changing `kubernetes_version` recreates the cluster — there is no in-place upgrade.

> **Note:** After `terraform apply` completes, the control plane needs ~10 minutes before it is reachable and the kubeconfig is fetchable.

## Fetching the kubeconfig

Kubeconfig is only retrievable once the control plane is reachable, so it must be fetched in a second apply. When `fetch_kubeconfig = true`, the module writes the kubeconfig to a local file (default `./.secrets/kubeconfig-<cluster_name>`, mode `0600`).

```hcl
module "nks" {
  # ...
  fetch_kubeconfig = true   # flip to true after the first apply
  # kubeconfig_path = "~/.kube/my-nks-cluster"   # optional override
}
```

1. `terraform apply` — creates the cluster (`fetch_kubeconfig = false`, the default).
2. Wait ~10 minutes for the control plane.
3. Flip `fetch_kubeconfig = true` and `terraform apply` again. The kubeconfig is written to disk and the path is available via the `kubeconfig_path` output.

Use it with `kubectl`:

```bash
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl get nodes
```

The default `.secrets/` directory is gitignored at the module root. If you set a custom `kubeconfig_path`, make sure it's gitignored too.

## Existing VPC

By default the module creates a new VPC. To use an existing VPC, set `create_vpc = false` and pass `vpc_id`:

```hcl
module "nks" {
  source  = "nirvana-labs/nks/nirvana"
  version = "~> 0.2.0"

  cluster_name       = "existing-vpc-demo"
  kubernetes_version = "v1.34.4"
  project_id         = var.project_id
  create_vpc         = false
  vpc_id             = nirvana_networking_vpc.this.id

  node_pools = {
    default = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
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
  version = "~> 0.2.0"

  cluster_name       = "multi-pool-demo"
  kubernetes_version = "v1.34.4"
  project_id         = var.project_id

  node_pools = {
    general = {
      node_count    = 1
      instance_type = "n1-highcpu-2"
    }
    compute = {
      node_count       = 1
      instance_type    = "n1-standard-2"
      boot_volume_size = 80
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
  source  = "nirvana-labs/nks/nirvana//modules/node-pool"
  version = "~> 0.2.0"

  cluster_id    = module.nks.cluster_id
  name          = "gpu"
  node_count    = 1
  instance_type = "n1-standard-2"
}
```

## Firewall rules

> **⚠️ Important:** `management_cidrs` and `ingress_cidrs` both default to `["0.0.0.0/0"]`, which exposes the Kubernetes API and ingress VIPs to the public internet. **Always** scope `management_cidrs` to your trusted networks (VPN, office egress, bastion) before using a cluster for anything non-trivial. `ingress_cidrs` may legitimately be `0.0.0.0/0` if the cluster serves public traffic, but be explicit about that choice.

The module creates default firewall rules for:

| Rule | Protocol | Ports | Source | Default |
|------|----------|-------|--------|---------|
| K8s API | TCP | 443 | `management_cidrs` | `0.0.0.0/0` (open) |
| HTTP/HTTPS ingress | TCP | 80, 443 | `ingress_cidrs` | `0.0.0.0/0` (open) |

```hcl
module "nks" {
  # ...
  management_cidrs = ["10.0.0.0/8", "203.0.113.42/32"]  # VPN + bastion
  ingress_cidrs    = ["0.0.0.0/0"]                       # public ingress
}
```

Management and ingress rules target the K8s API VIP and ingress VIP respectively (not the whole subnet). Intra-cluster traffic is allowed by the platform by default. Set `create_firewall_rules = false` to manage firewall rules externally.

## Autoscaling

Clusters created by this module opt into autoscaling by default. The NKS autoscaling controller manages each node pool's size — see the [Nirvana NKS autoscaling docs](https://docs.nirvanalabs.io/cloud/nks/autoscaling/) for full behavior.

What's immediately relevant for using this module:

- **Scale-up** is driven by pod resource _requests_ (not usage). Pending pods get matched against the declared `node_pools` and the best-fitting pool gets a new node. Pods with under-set requests can over-pack a node and degrade performance — set realistic requests.
- **Scale-down** consolidates workloads onto fewer nodes when utilization drops, cordoning the targeted node and draining its pods while respecting `PodDisruptionBudget`s and `terminationGracePeriodSeconds`.
- **Pool boundaries are respected.** The autoscaler picks among pools you've declared; it won't introduce new instance types on its own. To make a new shape available, add another `node_pools` entry.

In this shape, `node_count` on each pool is the **initial** size at cluster creation; after that, the controller is the source of truth for pool size. Re-applying Terraform with a different `node_count` will surface a diff, but the controller should be doing the scaling — see "Scaling node pools" below.

> **Note:** any `terraform apply` that includes a node pool resource in its plan will reset `node_count` to the config value, overriding autoscaler-managed sizes. Use `-target` to scope applies that aren't intended to resize pools, or update the config to the current observed count before applying.

Opt out by setting `autoscaling = false`:

```hcl
module "nks" {
  # ...
  autoscaling = false
}
```

When opted out, pools are fixed-size. Increasing `node_count` and re-applying is the supported way to add capacity. Removing capacity has the same rules as the autoscaling-on case below.

> **Upgrading from earlier module versions:** the `autoscaling` variable is new. Module versions before this one didn't pass the field to the cluster resource, so existing clusters will see it explicitly set to `true` on the next `terraform apply` unless you override. If a cluster has been running with fixed-size pools and you want to keep it that way, set `autoscaling = false` before applying.

## Scaling node pools

Growing a pool by increasing `node_count` is graceful in both modes — the platform allocates new workers and they join the cluster.

Shrinking a pool by decreasing `node_count` (via Terraform, dashboard slider, or CLI) is currently disruptive: the platform picks a worker and terminates it without cordon, drain, `PodDisruptionBudget` respect, or volume detach, so anything running on that node is killed abruptly.

Two ways to remove capacity gracefully today:

- **Enable autoscaling** (the default). The NKS autoscaling controller scales pools down for you, cordoning nodes and draining workloads while respecting your `PodDisruptionBudget`s and `terminationGracePeriodSeconds`.
- **Surgical removal via API or UI.** To target a specific worker yourself, do the preflight before invoking the per-node delete action:

  1. Cordon the node: `kubectl cordon <node>`
  2. Drain it: `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
  3. Migrate or detach any persistent volumes the node was using.
  4. Delete the node by ID via the API or dashboard.

## Examples

- [Basic](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/basic) — Minimal cluster with a single worker pool
- [Multiple pools](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/multi-pool) — Heterogeneous worker pools with restricted management CIDRs
- [Labeled pools](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/labeled-pools) — Node pools with Kubernetes labels for nodeSelector / nodeAffinity targeting
- [Existing VPC](https://github.com/nirvana-labs/terraform-nirvana-nks/tree/main/examples/existing-vpc) — Cluster in a pre-existing VPC

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.0 |
| <a name="requirement_nirvana"></a> [nirvana](#requirement\_nirvana) | >= 1.50 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.0 |
| <a name="provider_nirvana"></a> [nirvana](#provider\_nirvana) | 1.50.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [local_sensitive_file.kubeconfig](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file) | resource |
| [nirvana_networking_firewall_rule.api](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_firewall_rule) | resource |
| [nirvana_networking_firewall_rule.ingress](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_firewall_rule) | resource |
| [nirvana_networking_vpc.this](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/networking_vpc) | resource |
| [nirvana_nks_cluster.this](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/nks_cluster) | resource |
| [nirvana_nks_node_pool.workers](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/resources/nks_node_pool) | resource |
| [nirvana_networking_vpc.existing](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/data-sources/networking_vpc) | data source |
| [nirvana_nks_cluster_kubeconfig.this](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest/docs/data-sources/nks_cluster_kubeconfig) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | Whether the cluster opts into autoscaling. Default true (recommended): the NKS autoscaling controller scales node pools to match pod demand with graceful drain on scale-down. Set to false for fixed-size pools you grow manually via node\_count; see README for graceful capacity-removal options. | `bool` | `true` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the NKS cluster. | `string` | `"my-cluster"` | no |
| <a name="input_create_firewall_rules"></a> [create\_firewall\_rules](#input\_create\_firewall\_rules) | Whether to create the default access firewall rules. | `bool` | `true` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Whether to create a new VPC. Set to false and provide vpc\_id to use an existing VPC. | `bool` | `true` | no |
| <a name="input_fetch_kubeconfig"></a> [fetch\_kubeconfig](#input\_fetch\_kubeconfig) | Whether to fetch the cluster kubeconfig and write it to kubeconfig\_path. Set to true only after the cluster is ready (~10 minutes after initial apply); fetching before the control plane is reachable will fail. | `bool` | `false` | no |
| <a name="input_ingress_cidrs"></a> [ingress\_cidrs](#input\_ingress\_cidrs) | CIDRs allowed to access the shared ingress (HTTP 80, HTTPS 443). | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_kubeconfig_path"></a> [kubeconfig\_path](#input\_kubeconfig\_path) | Path to write the kubeconfig file when fetch\_kubeconfig is true. Defaults to .secrets/kubeconfig-<cluster\_name> relative to the root module. | `string` | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the cluster (e.g. "v1.34.4"). Look up available versions via the nirvana\_nks\_cluster\_kubernetes\_versions data source. Changing this value recreates the cluster — there is no in-place upgrade. | `string` | n/a | yes |
| <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs) | CIDRs allowed to access the Kubernetes API (443). | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Map of worker node pool definitions. Keys are pool names. | <pre>map(object({<br/>    node_count       = number<br/>    instance_type    = string<br/>    boot_volume_size = optional(number, 64)<br/>    boot_volume_type = optional(string, "abs")<br/>    labels           = optional(map(string), {})<br/>    tags             = optional(list(string), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Nirvana Labs project ID. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Nirvana Labs region to deploy in. | `string` | `"us-sva-2"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to attach to all resources. | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of an existing VPC. Required when create\_vpc is false. Only one NKS cluster per VPC is supported. | `string` | `null` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name for the created VPC and subnet. Defaults to cluster\_name. Ignored when vpc\_id is set. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the NKS cluster. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the NKS cluster. |
| <a name="output_cluster_private_ip"></a> [cluster\_private\_ip](#output\_cluster\_private\_ip) | Private IP (K8s API VIP) of the cluster. |
| <a name="output_cluster_public_ip"></a> [cluster\_public\_ip](#output\_cluster\_public\_ip) | Public IP of the cluster. |
| <a name="output_cluster_status"></a> [cluster\_status](#output\_cluster\_status) | Status of the cluster. |
| <a name="output_ingress_vip"></a> [ingress\_vip](#output\_ingress\_vip) | Private IP of the shared ingress. |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Kubeconfig for the cluster. Null unless fetch\_kubeconfig is true. |
| <a name="output_kubeconfig_path"></a> [kubeconfig\_path](#output\_kubeconfig\_path) | Path to the written kubeconfig file. Null unless fetch\_kubeconfig is true. |
| <a name="output_node_pool_ids"></a> [node\_pool\_ids](#output\_node\_pool\_ids) | Map of worker node pool names to their IDs. |
| <a name="output_subnet_cidr"></a> [subnet\_cidr](#output\_subnet\_cidr) | CIDR of the VPC subnet. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC (created or existing). |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Nirvana Labs](https://nirvanalabs.io/).

## License

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.
