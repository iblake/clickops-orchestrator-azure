module "vm" {
  # Hybrid pattern filter: only create NEW VMs (existing VMs not supported)
  # Virtual machines always created fresh - no existing VM support in hybrid pattern
  for_each = local.virtual_machines
  source   = "Azure/avm-res-compute-virtualmachine/azurerm"
  version  = "0.19.0"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku_size            = each.value.size
  zone                = null
  admin_username      = each.value.admin_username

  admin_ssh_keys = [{
    public_key = each.value.ssh_public_key
    username   = each.value.admin_username
  }]

  os_type                         = "Linux"
  disable_password_authentication = true
  provision_vm_agent              = true
  encryption_at_host_enabled      = false
  boot_diagnostics                = false

  # Network configuration
  network_interfaces = {
    nic = {
      name = "${each.value.name}-nic"
      network_security_groups = {
        nsg_association = {
          network_security_group_resource_id = local.resource_ids.security_groups[each.value.security_group_key]
        }
      }
      ip_configurations = {
        ipconfig1 = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = local.resource_ids.subnets[each.value.network_key][each.value.subnet_key]
          private_ip_address_allocation = "Dynamic"
          create_public_ip_address      = each.value.create_public_ip
          public_ip_address_name        = each.value.create_public_ip ? "${each.value.name}-publicip" : null
          public_ip_address_sku         = each.value.public_ip_sku
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
    name                 = "${each.value.name}-osdisk"
  }
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  depends_on = [module.resource_group, module.vnet, module.nsg]
}