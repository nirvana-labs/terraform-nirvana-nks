resource "nirvana_networking_vpc" "this" {
  name        = "my-vpc"
  project_id  = var.project_id
  region      = "us-sva-2"
  subnet_name = "my-subnet"
}

module "nks" {
  source = "../../"

  cluster_name = "existing-vpc-demo"
  project_id   = var.project_id
  region       = "us-sva-2"
  create_vpc   = false
  vpc_id       = nirvana_networking_vpc.this.id

  node_pools = {
    default = {
      node_count    = 2
      instance_type = "n1-standard-8"
    }
  }

  # Firewall rules default to 0.0.0.0/0 for both the K8s API and ingress VIPs.
  # Scope management_cidrs to your trusted networks before using this cluster for anything non-trivial.
  # management_cidrs = ["10.0.0.0/8"]   # e.g. VPN / bastion egress
  # ingress_cidrs    = ["0.0.0.0/0"]    # public ingress (default)
}
