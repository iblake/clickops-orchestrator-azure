################################################################################
#  Data sources for existing networks
################################################################################
data "azurerm_virtual_network" "existing" {
  count               = var.network.existing_vnet_name != null ? 1 : 0
  name                = var.network.existing_vnet_name
  resource_group_name = var.network.existing_resource_group
}

data "azurerm_subnet" "existing" {
  count                = var.network.existing_subnet_name != null ? 1 : 0
  name                 = var.network.existing_subnet_name
  virtual_network_name = var.network.existing_vnet_name
  resource_group_name  = var.network.existing_resource_group
}

################################################################################
#  Virtual Network & Subnets (AVM Module) - Only if not using existing
################################################################################
module "vnet" {
  count   = var.network.existing_vnet_name == null && var.network.vnet_name != null && var.network.vnet_cidr != null ? 1 : 0
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.9.2"

  name                = var.network.vnet_name
  location            = var.resource_group.existing_name != null ? data.azurerm_resource_group.existing[0].location : var.resource_group.location
  resource_group_name = var.resource_group.existing_name != null ? data.azurerm_resource_group.existing[0].name : (length(module.resource_group) > 0 ? module.resource_group[0].name : "")
  address_space       = [var.network.vnet_cidr]

  subnets = {
    main = {
      name             = var.network.subnet_name
      address_prefixes = [var.network.subnet_cidr]
    }
  }
}