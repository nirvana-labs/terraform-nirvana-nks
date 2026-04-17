terraform {
  required_version = ">= 1.5"

  required_providers {
    nirvana = {
      source  = "nirvana-labs/nirvana"
      version = ">= 1.41"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}
