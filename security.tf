module "nsg" {
  for_each = {
    for key, config in local.security_groups : key => config
    if !config.is_existing
  }
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  security_rules = {
    for rule in each.value.rules :
    rule.name => {
      name                       = rule.name
      priority                   = rule.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = rule.protocol
      source_port_range          = "*"
      destination_port_range     = tostring(rule.port)
      source_address_prefix      = rule.source
      destination_address_prefix = "*"
    }
  }

  depends_on = [module.resource_group, data.azurerm_resource_group.existing]
}