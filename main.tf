resource "nirvana_networking_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  name        = coalesce(var.vpc_name, var.cluster_name)
  project_id  = var.project_id
  region      = var.region
  subnet_name = coalesce(var.vpc_name, var.cluster_name)
  tags        = var.tags
}

data "nirvana_networking_vpc" "existing" {
  count = var.create_vpc ? 0 : 1

  vpc_id = var.vpc_id
}

locals {
  vpc_id      = var.create_vpc ? nirvana_networking_vpc.this[0].id : var.vpc_id
  subnet_cidr = var.create_vpc ? nirvana_networking_vpc.this[0].subnet.cidr : data.nirvana_networking_vpc.existing[0].subnet.cidr
}

resource "nirvana_nks_cluster" "this" {
  name       = var.cluster_name
  project_id = var.project_id
  region     = var.region
  vpc_id     = local.vpc_id
  tags       = var.tags
}

resource "nirvana_nks_node_pool" "workers" {
  for_each = var.node_pools

  cluster_id = nirvana_nks_cluster.this.id
  name       = each.key
  node_count = each.value.node_count

  node_config = {
    instance_type = each.value.instance_type
    boot_volume = {
      size = each.value.boot_volume_size
      type = each.value.boot_volume_type
    }
    labels = [for k, v in each.value.labels : "${k}=${v}"]
  }

  tags = concat(var.tags, each.value.tags)
}

data "nirvana_nks_cluster_kubeconfig" "this" {
  count = var.fetch_kubeconfig ? 1 : 0

  cluster_id = nirvana_nks_cluster.this.id
}

resource "local_sensitive_file" "kubeconfig" {
  count = var.fetch_kubeconfig ? 1 : 0

  content         = data.nirvana_nks_cluster_kubeconfig.this[0].kubeconfig
  filename        = coalesce(var.kubeconfig_path, "${path.root}/.secrets/kubeconfig-${var.cluster_name}")
  file_permission = "0600"
}
