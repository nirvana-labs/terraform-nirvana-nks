terraform {
  required_version = ">= 1.5"

  required_providers {
    # >= 1.52.25 is required by nirvana_nks_cluster, not just preferred. Earlier
    # releases wait only the SDK's 10 minute default on the cluster-create
    # operation, while a cold cluster takes ~20 minutes to reach ready. The apply
    # then fails with "operation timed out after 10m0s" AFTER the cluster was
    # created but BEFORE Terraform wrote state, orphaning it — so a re-apply
    # builds a second cluster and recovery needs a manual import.
    nirvana = {
      source  = "nirvana-labs/nirvana"
      version = ">= 1.52.25"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}
