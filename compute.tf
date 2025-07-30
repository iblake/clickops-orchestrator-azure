################################################################################
#  Virtual Machine (AVM Module) - Create from JSON config or override
################################################################################

# Get the first VM from configuration (simplified for MVP)
locals {
  primary_vm = length(local.virtual_machines) > 0 ? values(local.virtual_machines)[0] : null
  effective_vm = var.vm_override != null ? {
    name                = var.vm_override.name
    resource_group_name = var.resource_group_override != null ? var.resource_group_override.name : local.primary_resource_group.name
    location            = var.resource_group_override != null ? var.resource_group_override.location : local.primary_resource_group.location
    size                = var.vm_override.size
    admin_username      = var.vm_override.admin_username
    ssh_key_path        = var.vm_override.ssh_key_path
    create_public_ip    = coalesce(var.vm_override.create_public_ip, true)
    public_ip_sku       = coalesce(var.vm_override.public_ip_sku, "Basic")
  } : local.primary_vm
}

module "vm" {
  count   = local.effective_vm != null && local.effective_resource_group != null && local.effective_network != null ? 1 : 0
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.19.0"

  name                = local.effective_vm.name
  location            = local.effective_vm.location
  resource_group_name = var.enable_existing_resources && length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].name : (length(module.resource_group) > 0 ? module.resource_group[0].name : "")
  sku_size            = local.effective_vm.size
  zone                = null
  admin_username      = local.effective_vm.admin_username

  admin_ssh_keys = [{
    public_key = file(pathexpand(local.effective_vm.ssh_key_path))
    username   = local.effective_vm.admin_username
  }]

  os_type                         = "Linux"
  disable_password_authentication = true
  provision_vm_agent              = true
  encryption_at_host_enabled      = false
  boot_diagnostics                = false

  network_interfaces = {
    nic = {
      name = "${local.effective_vm.name}-nic"
      network_security_groups = {
        nsg_association = {
          network_security_group_resource_id = var.enable_existing_resources && length(data.azurerm_network_security_group.existing) > 0 ? data.azurerm_network_security_group.existing[0].id : (length(module.nsg) > 0 ? module.nsg[0].resource_id : null)
        }
      }
      ip_configurations = {
        ipconfig1 = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = var.enable_existing_resources && length(data.azurerm_subnet.existing) > 0 ? data.azurerm_subnet.existing[0].id : (length(module.vnet) > 0 ? module.vnet[0].subnets[keys(local.effective_network.subnets)[0]].resource_id : null)
          private_ip_address_allocation = "Dynamic"
          create_public_ip_address      = local.effective_vm.create_public_ip
          public_ip_address_name        = local.effective_vm.create_public_ip ? "${local.effective_vm.name}-publicip" : null
          public_ip_address_sku         = local.effective_vm.public_ip_sku
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
    name                 = "${local.effective_vm.name}-osdisk"
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}