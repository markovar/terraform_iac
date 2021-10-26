locals {
  prefix = "iac${terraform.workspace == "default" ? "dev1" : terraform.workspace}"
}

# Create a resource group
resource "azurerm_resource_group" "patito" {
  name     = "${local.prefix}-${var.environment}-rg"
  location = "centralus"
  tags = {
    "env" = "${var.environment}"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.prefix}-${var.environment}-iacvnet"
  location            = azurerm_resource_group.patito.location
  resource_group_name = azurerm_resource_group.patito.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    "env" = "${var.environment}"
  }
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${local.prefix}-${var.environment}-iacsubnet1"
  resource_group_name  = azurerm_resource_group.patito.name
  address_prefixes     = ["10.0.0.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_network_interface" "nic" {
  count               = var.cantidad-servers
  name                = "${local.prefix}-${var.environment}-iacnic${count.index}"
  location            = azurerm_resource_group.patito.location
  resource_group_name = azurerm_resource_group.patito.name
  ip_configuration {
    name                          = "${local.prefix}-${var.environment}-iacipconfig${count.index}"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip[count.index].id
  }
  tags = {
    "env" = "${var.environment}"
  }
}

resource "azurerm_virtual_machine" "vm" {
  count                 = var.cantidad-servers
  name                  = "${local.prefix}-${var.environment}-iacvm${count.index}"
  location              = azurerm_resource_group.patito.location
  resource_group_name   = azurerm_resource_group.patito.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  vm_size               = "Standard_D1_v2"

  delete_data_disks_on_termination = "true"
  delete_os_disk_on_termination    = "true"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${local.prefix}-${var.environment}-iacos${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${local.prefix}-${var.environment}-pc${count.index}"
    admin_username = var.linux-user
    admin_password = var.linux-password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    "env" = "${var.environment}"
  }
}

resource "azurerm_public_ip" "publicip" {
  count               = var.cantidad-servers
  name                = "${local.prefix}-${var.environment}iacpublicip${count.index}"
  location            = azurerm_resource_group.patito.location
  resource_group_name = azurerm_resource_group.patito.name
  allocation_method   = "Static"
  tags = {
    "env" = "${var.environment}"
  }
}

resource "azurerm_network_security_group" "iacsecgroup" {
  name                = "${local.prefix}-${var.environment}-iacSecGroup"
  location            = azurerm_resource_group.patito.location
  resource_group_name = azurerm_resource_group.patito.name
  tags = {
    "env" = "${var.environment}"
  }
}

resource "azurerm_network_security_rule" "rule01" {
  name                        = "DenegarTodo"
  network_security_group_name = azurerm_network_security_group.iacsecgroup.name
  resource_group_name         = azurerm_resource_group.patito.name
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "rule02" {
  name                        = "permitael80"
  network_security_group_name = azurerm_network_security_group.iacsecgroup.name
  resource_group_name         = azurerm_resource_group.patito.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "rule03" {
  name                        = "permitael22"
  network_security_group_name = azurerm_network_security_group.iacsecgroup.name
  resource_group_name         = azurerm_resource_group.patito.name
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_interface_security_group_association" "sgassociation" {
  count                     = var.cantidad-servers
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.iacsecgroup.id
}