################################################################################
#  Virtual Machine (AVM Module)
################################################################################
module "vm" {
  count   = (var.resource_group.existing_name != null || (var.resource_group.name != null && var.resource_group.location != null)) && (var.network.existing_vnet_name != null || (var.network.vnet_name != null && var.network.vnet_cidr != null)) ? 1 : 0
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.0"

  name                = var.vm.name
  location            = var.resource_group.existing_name != null ? data.azurerm_resource_group.existing[0].location : var.resource_group.location
  resource_group_name = var.resource_group.existing_name != null ? data.azurerm_resource_group.existing[0].name : (length(module.resource_group) > 0 ? module.resource_group[0].name : "")
  sku_size            = var.vm.size
  zone                = null
  admin_username      = var.vm.admin_username

  admin_ssh_keys = [{
    public_key = file(pathexpand(var.vm.ssh_key_path))
    username   = var.vm.admin_username
  }]

  os_type                         = "Linux"
  disable_password_authentication = true
  provision_vm_agent              = true
  encryption_at_host_enabled      = false
  boot_diagnostics                = false

  network_interfaces = {
    nic = {
      name = "${var.vm.name}-nic"
      network_security_groups = {
        nsg_association = {
          network_security_group_resource_id = var.security.existing_nsg_name != null ? data.azurerm_network_security_group.existing[0].id : (length(module.nsg) > 0 ? module.nsg[0].resource_id : null)
        }
      }
      ip_configurations = {
        ipconfig1 = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = var.network.existing_subnet_name != null ? data.azurerm_subnet.existing[0].id : (length(module.vnet) > 0 ? module.vnet[0].subnets["main"].resource_id : null)
          private_ip_address_allocation = "Dynamic"
          create_public_ip_address      = var.vm.create_public_ip
          public_ip_address_name        = var.vm.create_public_ip ? "${var.vm.name}-publicip" : null
          public_ip_address_sku         = var.vm.public_ip_sku
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
    name                 = "${var.vm.name}-osdisk"
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}