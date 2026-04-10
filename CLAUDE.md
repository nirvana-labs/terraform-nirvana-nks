# terraform-nirvana-nks

Public Terraform module for provisioning NKS (Nirvana Kubernetes Service) clusters on Nirvana Labs infrastructure.

## Architecture

NKS clusters are created via the Nirvana Cloud provisioning service API. The control plane is fully platform-managed — customers only define worker node pools. This module wraps the `nirvana_nks_cluster` and `nirvana_nks_node_pool` provider resources with sensible defaults, firewall rules, and optional VPC creation.

## Project structure

- `main.tf` — VPC (conditional), NKS cluster, worker node pools
- `variables.tf` — Public variable API
- `outputs.tf` — Cluster IPs, VPC, ingress VIP, node pool IDs
- `firewall.tf` — Default access firewall rules
- `versions.tf` — Provider version constraints (nirvana-labs/nirvana >= 1.32)
- `modules/node-pool/` — Standalone submodule for adding pools to an existing cluster independently
- `examples/basic/` — Minimal cluster with a single worker pool
- `examples/multi-pool/` — Multiple heterogeneous worker pools
- `examples/existing-vpc/` — Cluster in a pre-existing VPC

## Terraform provider

Uses the [nirvana-labs/nirvana](https://registry.terraform.io/providers/nirvana-labs/nirvana/latest) provider.

- Provider source code: `../terraform-provider-nirvana`
- Auth: set `NIRVANA_LABS_API_KEY` env var (see `.env.example`; load with `set -a; source .env; set +a`)
- NKS is currently available in `us-sva-2` only
- ICMP is always allowed on Nirvana VPCs (no firewall rule needed)

## Key design decisions

- **One cluster per VPC** — the platform does not support multiple NKS clusters in a single VPC
- **Control plane is platform-managed** — no control plane node pool variables; customers only configure worker pools via `node_pools`
- **Firewall rules are module-managed** — the provisioning service does NOT create firewall rules. The module creates default rules for K8s API (6443) and HTTP/HTTPS ingress (80/443). Intra-cluster traffic is allowed by the platform by default. Toggle with `create_firewall_rules = false`
- **VIP allocation** — K8s API VIP is the last usable IP in the subnet; shared ingress VIP is the second-to-last. Both are computed from `subnet_cidr` in `firewall.tf` locals
- **Existing VPC support** — set `create_vpc = false` and pass `vpc_id`. Uses a `create_vpc` bool (not null-checking `vpc_id`) so that `count` is always known at plan time, avoiding issues when `vpc_id` comes from a resource output. The module looks up the VPC via a data source to discover `subnet_cidr`

## Networking

- K8s API is exposed on the last usable IP in the VPC subnet (the cluster's `private_ip` / VIP)
- Shared ingress is exposed on the second-to-last IP
- Firewall rules for management access target the API VIP specifically (`/32`), not the whole subnet
- Firewall rules for ingress target the ingress VIP specifically (`/32`)

## Firewall ports

- **Management (per CIDR):** TCP 6443 (K8s API)
- **Ingress (per CIDR):** TCP 80, 443 (HTTP/HTTPS via shared ingress)
- Intra-cluster traffic is allowed by the platform by default — no firewall rules needed

## Validation

```bash
terraform fmt -check -recursive
terraform init -backend=false && terraform validate          # root module
cd modules/node-pool && terraform init -backend=false && terraform validate
cd examples/basic && terraform init -backend=false && terraform validate
cd examples/multi-pool && terraform init -backend=false && terraform validate
cd examples/existing-vpc && terraform init -backend=false && terraform validate
```

## Examples use local source

Examples currently use `source = "../../"` for local development. Update to `source = "nirvana-labs/nks/nirvana"` before publishing to the Terraform registry.

## Code style

- Prefer linking to documentation over reiterating it in comments
- Keep the public variable API minimal — avoid exposing internal platform details
- Use structured objects (`map(object)`) for collections, not flat count-based variables
