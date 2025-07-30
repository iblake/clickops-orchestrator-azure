################################################################################
#  Data sources for existing networks
################################################################################
data "azurerm_virtual_network" "existing" {
  count               = var.enable_existing_resources && var.network_override != null && var.network_override.existing_vnet_name != null ? 1 : 0
  name                = var.network_override.existing_vnet_name
  resource_group_name = var.network_override.existing_resource_group
}

data "azurerm_subnet" "existing" {
  count                = var.enable_existing_resources && var.network_override != null && var.network_override.existing_subnet_name != null ? 1 : 0
  name                 = var.network_override.existing_subnet_name
  virtual_network_name = var.network_override.existing_vnet_name
  resource_group_name  = var.network_override.existing_resource_group
}

################################################################################
#  Virtual Network & Subnets (AVM Module) - Create from JSON config
################################################################################

# Get the first network from configuration (simplified for MVP)
locals {
  primary_network = length(local.networks) > 0 ? values(local.networks)[0] : null
  effective_network = var.network_override != null ? {
    name                = var.network_override.vnet_name
    resource_group_name = var.resource_group_override != null ? var.resource_group_override.name : local.primary_resource_group.name
    location            = var.resource_group_override != null ? var.resource_group_override.location : local.primary_resource_group.location
    cidr                = var.network_override.vnet_cidr
    subnets = {
      main = {
        name = var.network_override.subnet_name
        cidr = var.network_override.subnet_cidr
      }
    }
  } : local.primary_network
}

module "vnet" {
  count   = local.effective_network != null && !(var.enable_existing_resources && var.network_override != null && var.network_override.existing_vnet_name != null) ? 1 : 0
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.9.2"

  name                = local.effective_network.name
  location            = local.effective_network.location
  resource_group_name = var.enable_existing_resources && length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].name : (length(module.resource_group) > 0 ? module.resource_group[0].name : "")
  address_space       = [local.effective_network.cidr]

  subnets = {
    for subnet_key, subnet in local.effective_network.subnets : subnet_key => {
      name             = subnet.name
      address_prefixes = [subnet.cidr]
    }
  }
}