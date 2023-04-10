terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.51.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# locals {
#   vmmachinenicmapping = {
#     for key, value in var.vmmachines : value => {
#       vm : value,
#       nic : join("", ["testnicprafull", split("-", value)[1]])
#     }
#   }
# }

resource "azurerm_resource_group" "testrgprafull" {
  name     = "testrgprafull"
  location = "West Europe"
}

resource "azurerm_virtual_network" "testvnetprafull" {
  name                = "testvnetprafull"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.testrgprafull.location
  resource_group_name = azurerm_resource_group.testrgprafull.name
}

resource "azurerm_subnet" "testsubnetprafull" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.testrgprafull.name
  virtual_network_name = azurerm_virtual_network.testvnetprafull.name
  address_prefixes     = ["10.0.2.0/24"]
}

# resource "azurerm_public_ip" "testpublicip" {
#   name                = "testpublicip"
#   resource_group_name = azurerm_resource_group.testrgprafull.name
#   location            = azurerm_resource_group.testrgprafull.location
#   allocation_method   = "Static"
# }

resource "azurerm_network_interface" "testnicprafull" {
  for_each            = var.vms
  name                = each.value.nic
  location            = azurerm_resource_group.testrgprafull.location
  resource_group_name = azurerm_resource_group.testrgprafull.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.testsubnetprafull.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.testpublicip.id
    # public_ip_address             = azurerm_public_ip.testpublicip.ip_address
  }

}

resource "azurerm_linux_virtual_machine" "testvmprafull" {
  for_each            = var.vms
  name                = each.key
  resource_group_name = azurerm_resource_group.testrgprafull.name
  location            = azurerm_resource_group.testrgprafull.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.testnicprafull[each.key].id
  ]

  depends_on = [
    azurerm_network_interface.testnicprafull
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  # os_disk {
  #   caching              = "ReadWrite"
  #   storage_account_type = "Standard_LRS"
  # }

  dynamic "os_disk" {
    for_each = [1]

    content {
      caching              = "ReadWrite"
      storage_account_type = each.key == "my-vm01" ? "StandardSSD_LRS" : "Standard_LRS"
    }
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "postvmprovisioning" {
  for_each             = var.vms
  name                 = "postvmprovisioning"
  virtual_machine_id   = azurerm_linux_virtual_machine.testvmprafull[each.key].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
  {
    "script" : "${base64encode(file(var.bashscriptfile))}"
  }
  SETTINGS
}
