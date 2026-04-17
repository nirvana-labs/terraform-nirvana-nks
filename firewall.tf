locals {
  subnet_mask = tonumber(split("/", local.subnet_cidr)[1])
  host_count  = pow(2, 32 - local.subnet_mask) - 2

  # K8s API VIP is the last usable IP in the subnet
  api_vip = cidrhost(local.subnet_cidr, local.host_count)
  # Shared ingress VIP is the second-to-last IP
  ingress_vip = cidrhost(local.subnet_cidr, local.host_count - 1)
}

# K8s API access (6443) — targets the API VIP
resource "nirvana_networking_firewall_rule" "api" {
  for_each = var.create_firewall_rules ? toset(var.management_cidrs) : toset([])

  name                = "${var.cluster_name}-api-${replace(replace(each.value, ".", "-"), "/", "-")}"
  vpc_id              = local.vpc_id
  protocol            = "tcp"
  source_address      = each.value
  destination_address = "${local.api_vip}/32"
  destination_ports   = ["6443"]
  tags                = var.tags
}

# Ingress access (HTTP/HTTPS) — targets the shared ingress VIP
resource "nirvana_networking_firewall_rule" "ingress" {
  for_each = var.create_firewall_rules ? toset(var.ingress_cidrs) : toset([])

  name                = "${var.cluster_name}-ingress-${replace(replace(each.value, ".", "-"), "/", "-")}"
  vpc_id              = local.vpc_id
  protocol            = "tcp"
  source_address      = each.value
  destination_address = "${local.ingress_vip}/32"
  destination_ports   = ["80", "443"]
  tags                = var.tags
}
