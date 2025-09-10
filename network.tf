module "vnet" {
  for_each = {
    for key, config in local.networks : key => config
    if !config.is_existing
  }
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.9.2"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  address_space       = [each.value.cidr]

  subnets = {
    for subnet_key, subnet in each.value.subnets : subnet_key => {
      name             = subnet.name
      address_prefixes = [subnet.cidr]
    }
  }

  depends_on = [module.resource_group, data.azurerm_resource_group.existing]
}