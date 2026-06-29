terraform {
  required_version = ">= 1.5"

  required_providers {
    nirvana = {
      source  = "nirvana-labs/nirvana"
      version = ">= 1.52.7"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}
