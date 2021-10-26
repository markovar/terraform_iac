terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "infra-control-rg"
    storage_account_name = "ucreativaiac"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
}

provider "azurerm" {
  features {}
}

variable "LINUX_PASSWORD" {
  sensitive = true
}

module "linux-server" {
  source           = "./modules/linux-server"
  linux-password   = var.LINUX_PASSWORD
  linux-user       = "adminfrb03"
  environment      = "dev"
  cantidad-servers = 1
}

output "PublicIP" {
    value = module.linux-server.ip-publica
}