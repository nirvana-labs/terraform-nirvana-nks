output "cluster_id" {
  value = module.nks.cluster_id
}

output "cluster_public_ip" {
  value = module.nks.cluster_public_ip
}

output "ingress_vip" {
  value = module.nks.ingress_vip
}

output "node_pool_ids" {
  value = module.nks.node_pool_ids
}

# TODO: Uncomment after adding kubeconfig to the provider.
# output "kubeconfig" {
#   value     = module.nks.kubeconfig
#   sensitive = true
# }
