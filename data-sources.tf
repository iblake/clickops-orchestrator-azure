# Data source for existing Resource Groups
data "azurerm_resource_group" "existing" {
  for_each = {
    for key, config in local.resource_groups : key => config
    if config.is_existing
  }
  name = each.value.name
}

# Data source for existing Virtual Networks
data "azurerm_virtual_network" "existing" {
  for_each = {
    for key, config in local.networks : key => config
    if config.is_existing
  }
  name                = each.value.name
  resource_group_name = local.resolved_resource_group_names.networks[each.key]
}

# Data source for existing Subnets
data "azurerm_subnet" "existing" {
  for_each = local.existing_subnets

  name                 = each.value.name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

# Data source for existing Network Security Groups
data "azurerm_network_security_group" "existing" {
  for_each = {
    for key, config in local.security_groups : key => config
    if config.is_existing
  }
  name                = each.value.name
  resource_group_name = local.resolved_resource_group_names.security_groups[each.key]
}