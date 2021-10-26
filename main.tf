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

variable "linux_password" {
  sensitive = true
}

variable "client_id" {  
  sensitive = true
}

variable "client_secret" {
  sensitive = true
}

module "linux-server" {
  source           = "./modules/linux-server"
  linux-password   = var.linux_password
  linux-user       = "adminfrb03"
  environment      = "dev"
  cantidad-servers = 1
}