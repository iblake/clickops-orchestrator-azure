################################################################################
#  Data source for existing resource group
################################################################################
data "azurerm_resource_group" "existing" {
  count = var.enable_existing_resources && var.resource_group_override != null && var.resource_group_override.existing_name != null ? 1 : 0
  name  = var.resource_group_override.existing_name
}

################################################################################
#  Resource Group (AVM Module) - Create from JSON config or override
################################################################################

# Get the first resource group from configuration (simplified for MVP)
locals {
  primary_resource_group = length(local.resource_groups) > 0 ? values(local.resource_groups)[0] : null
  effective_resource_group = var.resource_group_override != null ? {
    name     = var.resource_group_override.name
    location = var.resource_group_override.location
  } : local.primary_resource_group
}

module "resource_group" {
  count   = local.effective_resource_group != null && !(var.enable_existing_resources && var.resource_group_override != null && var.resource_group_override.existing_name != null) ? 1 : 0
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = local.effective_resource_group.name
  location = local.effective_resource_group.location
}