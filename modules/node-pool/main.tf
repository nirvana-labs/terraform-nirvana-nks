resource "nirvana_nks_node_pool" "this" {
  cluster_id = var.cluster_id
  name       = var.name
  node_count = var.node_count

  node_config = {
    instance_type = var.instance_type
    boot_volume = {
      size = var.boot_volume_size
      type = var.boot_volume_type
    }
  }

  tags = var.tags
}
