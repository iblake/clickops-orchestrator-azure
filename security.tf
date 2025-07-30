################################################################################
#  Data source for existing NSG
################################################################################
data "azurerm_network_security_group" "existing" {
  count               = var.enable_existing_resources && var.security_override != null && var.security_override.existing_nsg_name != null ? 1 : 0
  name                = var.security_override.existing_nsg_name
  resource_group_name = var.security_override.existing_nsg_resource_group
}

################################################################################
#  Network Security Group (AVM Module) - Create from JSON config or override
################################################################################

# Get the first security group from configuration (simplified for MVP)
locals {
  primary_security_group = length(local.security_groups) > 0 ? values(local.security_groups)[0] : null
  effective_security_group = var.security_override != null ? {
    name                = coalesce(var.security_override.existing_nsg_name, "${local.primary_vm_name}-nsg")
    resource_group_name = var.resource_group_override != null ? var.resource_group_override.name : local.primary_resource_group.name
    location            = var.resource_group_override != null ? var.resource_group_override.location : local.primary_resource_group.location
    rules               = coalesce(var.security_override.rules, [])
  } : local.primary_security_group

  # Get primary VM name for NSG naming
  primary_vm_name = length(local.virtual_machines) > 0 ? values(local.virtual_machines)[0].name : "default-vm"
}

module "nsg" {
  count   = local.effective_security_group != null && !(var.enable_existing_resources && var.security_override != null && var.security_override.existing_nsg_name != null) ? 1 : 0
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  name                = local.effective_security_group.name
  location            = local.effective_security_group.location
  resource_group_name = var.enable_existing_resources && length(data.azurerm_resource_group.existing) > 0 ? data.azurerm_resource_group.existing[0].name : (length(module.resource_group) > 0 ? module.resource_group[0].name : "")

  security_rules = {
    for rule in local.effective_security_group.rules :
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