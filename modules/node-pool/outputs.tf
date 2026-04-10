output "id" {
  description = "ID of the node pool."
  value       = nirvana_nks_node_pool.this.id
}

output "name" {
  description = "Name of the node pool."
  value       = nirvana_nks_node_pool.this.name
}

output "status" {
  description = "Status of the node pool."
  value       = nirvana_nks_node_pool.this.status
}
