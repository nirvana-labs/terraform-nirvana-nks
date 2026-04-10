output "cluster_id" {
  description = "ID of the NKS cluster."
  value       = nirvana_nks_cluster.this.id
}

output "cluster_name" {
  description = "Name of the NKS cluster."
  value       = nirvana_nks_cluster.this.name
}

output "cluster_private_ip" {
  description = "Private IP (K8s API VIP) of the cluster."
  value       = nirvana_nks_cluster.this.private_ip
}

output "cluster_public_ip" {
  description = "Public IP of the cluster."
  value       = nirvana_nks_cluster.this.public_ip
}

output "cluster_status" {
  description = "Status of the cluster."
  value       = nirvana_nks_cluster.this.status
}

# TODO: Uncomment after adding kubeconfig to the nirvana_nks_cluster resource in the provider.
# output "kubeconfig" {
#   description = "Kubeconfig for the cluster."
#   value       = nirvana_nks_cluster.this.kubeconfig
#   sensitive   = true
# }

output "vpc_id" {
  description = "ID of the VPC (created or existing)."
  value       = local.vpc_id
}

output "subnet_cidr" {
  description = "CIDR of the VPC subnet."
  value       = local.subnet_cidr
}

output "ingress_vip" {
  description = "Private IP of the shared ingress (second-to-last IP in the subnet)."
  value       = local.ingress_vip
}

output "node_pool_ids" {
  description = "Map of worker node pool names to their IDs."
  value       = { for k, v in nirvana_nks_node_pool.workers : k => v.id }
}
