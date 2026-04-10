locals {
  subnet_mask = tonumber(split("/", local.subnet_cidr)[1])
  host_count  = pow(2, 32 - local.subnet_mask) - 2

  # K8s API VIP is the last usable IP in the subnet
  api_vip = cidrhost(local.subnet_cidr, local.host_count)
  # Shared Cilium ingress VIP is the second-to-last IP
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

# Ingress access (HTTP/HTTPS) — targets the shared Cilium ingress VIP
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

# RKE2 + Cilium intra-cluster TCP
# https://docs.rke2.io/install/requirements?cni-rules=Cilium#inbound-network-rules
resource "nirvana_networking_firewall_rule" "rke2_tcp" {
  count = var.create_firewall_rules ? 1 : 0

  name                = "${var.cluster_name}-rke2-tcp"
  vpc_id              = local.vpc_id
  protocol            = "tcp"
  source_address      = local.subnet_cidr
  destination_address = local.subnet_cidr
  destination_ports   = ["2379-2381", "4240", "4244", "6443", "9345", "10250", "30000-32767"]
  tags                = var.tags
}

# Cilium intra-cluster UDP (VXLAN + WireGuard)
# https://docs.rke2.io/install/requirements?cni-rules=Cilium#inbound-network-rules
resource "nirvana_networking_firewall_rule" "rke2_udp" {
  count = var.create_firewall_rules ? 1 : 0

  name                = "${var.cluster_name}-rke2-udp"
  vpc_id              = local.vpc_id
  protocol            = "udp"
  source_address      = local.subnet_cidr
  destination_address = local.subnet_cidr
  destination_ports   = ["8472", "51871"]
  tags                = var.tags
}
