variable "environment" {
  type    = string
  default = "dev"
}

variable "linux-password" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.linux-password) > 8
    error_message = "Password esta muy chiquito."
  }
  validation {
    condition     = substr(var.linux-password, 0, 3) != "123"
    error_message = "No puede comenzar con 123."
  }
}

variable "linux-user" {
  type      = string
  default   = "root"
  sensitive = true
}

variable "cantidad-servers" {
  type = number
  validation {
    condition     = var.cantidad-servers <= 2
    error_message = "Soy Pobre, no me deja crear mas de 2."
  }
}

output "ip-publica" {
  value = azurerm_public_ip.publicip.*.ip_address
}

output "resource-group-name" {
  value = azurerm_resource_group.patito.name
}

output "location" {
  value = azurerm_resource_group.patito.location
}