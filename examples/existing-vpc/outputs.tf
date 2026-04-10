output "cluster_id" {
  value = module.nks.cluster_id
}

output "cluster_public_ip" {
  value = module.nks.cluster_public_ip
}

output "vpc_id" {
  value = module.nks.vpc_id
}

# TODO: Uncomment after adding kubeconfig to the provider.
# output "kubeconfig" {
#   value     = module.nks.kubeconfig
#   sensitive = true
# }
