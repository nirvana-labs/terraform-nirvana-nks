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
}
