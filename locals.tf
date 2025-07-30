################################################################################
# Local Values - JSON Configuration Processing (OCI Landing Zones pattern)
################################################################################

locals {
  # Use variables from JSON files (passed via -var-file)
  resource_groups_config  = var.resource_groups
  networks_config         = var.networks
  security_groups_config  = var.security_groups
  virtual_machines_config = var.virtual_machines

  # Process Resource Groups
  resource_groups = {
    for key, config in local.resource_groups_config : key => {
      name     = config.name
      location = config.location
    }
  }

  # Process Networks with resolved resource group references
  networks = {
    for key, config in local.networks_config : key => {
      name                = config.name
      resource_group_name = local.resource_groups[config.resource_group_key].name
      location            = local.resource_groups[config.resource_group_key].location
      cidr                = config.cidr
      subnets = {
        for subnet_key, subnet_config in config.subnets : subnet_key => {
          name = subnet_config.name
          cidr = subnet_config.cidr
        }
      }
    }
  }

  # Process Security Groups with resolved resource group references
  security_groups = {
    for key, config in local.security_groups_config : key => {
      name                = config.name
      resource_group_name = local.resource_groups[config.resource_group_key].name
      location            = local.resource_groups[config.resource_group_key].location
      rules               = config.rules
    }
  }

  # Process Virtual Machines with all resolved references
  virtual_machines = {
    for key, config in local.virtual_machines_config : key => {
      name                = config.name
      resource_group_name = local.resource_groups[config.resource_group_key].name
      location            = local.resource_groups[config.resource_group_key].location
      size                = config.size
      admin_username      = config.admin_username
      ssh_key_path        = config.ssh_key_path
      create_public_ip    = try(config.create_public_ip, true)
      public_ip_sku       = try(config.public_ip_sku, "Basic")

      # Network references
      network_name = local.networks[config.network_key].name
      subnet_name  = local.networks[config.network_key].subnets[config.subnet_key].name

      # Security group reference
      security_group_name = local.security_groups[config.security_group_key].name
    }
  }

  # Create lookup maps for outputs
  resource_group_names = {
    for key, rg in local.resource_groups : key => rg.name
  }

  network_names = {
    for key, net in local.networks : key => net.name
  }

  security_group_names = {
    for key, sg in local.security_groups : key => sg.name
  }
}