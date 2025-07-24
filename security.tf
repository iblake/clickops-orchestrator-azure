################################################################################
#  Data source for existing NSG
################################################################################
data "azurerm_network_security_group" "existing" {
  count               = var.security.existing_nsg_name != null ? 1 : 0
  name                = var.security.existing_nsg_name
  resource_group_name = var.security.existing_nsg_resource_group
}

################################################################################
#  Network Security Group (AVM Module) - Only if not using existing
################################################################################
module "nsg" {
  count   = var.security.existing_nsg_name == null && (var.resource_group.existing_name != null || (var.resource_group.name != null && var.resource_group.location != null)) ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  name                = "${var.vm.name}-nsg"
  location            = var.resource_group.existing_name != null ? data.azurerm_resource_group.existing[0].location : var.resource_group.location
  resource_group_name = var.resource_group.existing_name != null ? data.azurerm_resource_group.existing[0].name : (length(module.resource_group) > 0 ? module.resource_group[0].name : "")

  security_rules = {
    for rule in var.security.rules :
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
}